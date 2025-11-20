codeunit 134344 "Document Totals Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Document Totals]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        InvoiceDiscountAmountErr: Label 'Invoice discount amount';
        InvoiceDiscountPercentErr: Label 'Invoice discount percent';
        IsInitialized: Boolean;
        WrongDecimalErr: Label 'Wrong count of decimals', Locked = true;
        InvoiceDiscountPerRoundingMsg: Label 'The system has recalculated the discount percentage to align with the rounded discount amount.';
        VATAmountErr: Label '%1 should be equal to %2', Comment = '%1 - VAT Amount Field, %2 - VAT Amount Field';

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure SalesQuoteUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Quote] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Quote card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::Quote);

        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");

        SalesQuote.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesQuote."Currency Code".AssistEdit();

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Invoice card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::Invoice);

        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");

        SalesInvoice.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesInvoice."Currency Code".AssistEdit();

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesInvoice."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesInvoice.Release.Invoke();
        SalesInvoice."Posting Date".SetValue(SalesInvoice."Posting Date".AsDate() + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 412765:
        SalesInvoice.Reopen.Invoke();
        SalesInvoice.Close();

        DeleteAllLinesFromSalesDocument(SalesHeader);
        CreateSalesLine(SalesHeader);
        CreateSalesLine(SalesHeader);

        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        SalesInvoice."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Order card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::Order);

        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        SalesOrder.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesOrder."Currency Code".AssistEdit();

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesOrder.Release.Invoke();
        SalesOrder."Posting Date".SetValue(SalesOrder."Posting Date".AsDate() + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 412765:
        SalesOrder.Reopen.Invoke();
        SalesOrder.Close();

        DeleteAllLinesFromSalesDocument(SalesHeader);
        CreateSalesLine(SalesHeader);
        CreateSalesLine(SalesHeader);

        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesOrder."Currency Code".AssistEdit();

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo] [FCY]
        // [SCENARIO 280259] Invoice discount amount remains unchanged after Currency Factor updated on Sales Credit Memo card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");

        SalesCreditMemo.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := SalesCreditMemo.SalesLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesCreditMemo."Currency Code".AssistEdit();

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesCreditMemo."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesCreditMemo.Release.Invoke();
        SalesCreditMemo."Posting Date".SetValue(SalesCreditMemo."Posting Date".AsDate() + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 412765:
        SalesCreditMemo.Reopen.Invoke();
        SalesCreditMemo.Close();

        DeleteAllLinesFromSalesDocument(SalesHeader);
        CreateSalesLine(SalesHeader);
        CreateSalesLine(SalesHeader);

        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        SalesCreditMemo."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Return Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Return Order card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::"Return Order");

        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.Filter.SetFilter("No.", SalesHeader."No.");

        SalesReturnOrder.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        SalesReturnOrder."Currency Code".AssistEdit();

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 280259
        SalesReturnOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 301110
        SalesReturnOrder.Release.Invoke();
        SalesReturnOrder."Posting Date".SetValue(SalesReturnOrder."Posting Date".AsDate() + 1);

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // Bug 412765:
        SalesReturnOrder.Reopen.Invoke();
        SalesReturnOrder.Close();

        DeleteAllLinesFromSalesDocument(SalesHeader);
        CreateSalesLine(SalesHeader);
        CreateSalesLine(SalesHeader);

        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.Filter.SetFilter("No.", SalesHeader."No.");

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        SalesReturnOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderUpdateCurrrencyFactor()
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Blanket Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Sales Return Order card page
        Initialize();

        CreateSalesHeaderWithCurrency(SalesHeader, SalesHeader."Document Type"::"Blanket Order");

        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        BlanketSalesOrder."Currency Code".AssistEdit();

        VerifySalesHeaderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Quote] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Quote card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Quote);

        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");

        PurchaseQuote.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseQuote.PurchLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := PurchaseQuote.PurchLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseQuote."Currency Code".AssistEdit();

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Invoice card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");

        PurchaseInvoice.PurchLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(10, 20));

        InvoiceDiscountAmount := PurchaseInvoice.PurchLines.InvoiceDiscountAmount.AsDecimal();
        InvoiceDiscountPercent := PurchaseInvoice.PurchLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseInvoice."Currency Code".AssistEdit();

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseInvoice."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseInvoice."Re&lease".Invoke(); // Release
        PurchaseInvoice."Posting Date".SetValue(PurchaseInvoice."Posting Date".AsDate() + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 412765:
        PurchaseInvoice.Reopen.Invoke();
        PurchaseInvoice.Close();

        DeleteAllLinesFromPurchaseDocument(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        PurchaseInvoice."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseOrderUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Order card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        PurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := PurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseOrder."Currency Code".AssistEdit();

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseOrder.Release.Invoke();
        PurchaseOrder."Posting Date".SetValue(PurchaseOrder."Posting Date".AsDate() + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 412765:
        PurchaseOrder.Reopen.Invoke();
        PurchaseOrder.Close();

        DeleteAllLinesFromPurchaseDocument(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseOrder."Currency Code".AssistEdit();

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [FCY]
        // [SCENARIO 280259] Invoice discount amount remains unchanged after Currency Factor updated on Purchase Credit Memo card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.Filter.SetFilter("No.", PurchaseHeader."No.");

        PurchaseCreditMemo.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseCreditMemo.PurchLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseCreditMemo."Currency Code".AssistEdit();

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseCreditMemo."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseCreditMemo.Release.Invoke();
        PurchaseCreditMemo."Posting Date".SetValue(PurchaseCreditMemo."Posting Date".AsDate() + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 412765:
        PurchaseCreditMemo.Reopen.Invoke();
        PurchaseCreditMemo.Close();

        DeleteAllLinesFromPurchaseDocument(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);

        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.Filter.SetFilter("No.", PurchaseHeader."No.");

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        PurchaseCreditMemo."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Return Order card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        PurchaseReturnOrder.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := PurchaseReturnOrder.PurchLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseReturnOrder."Currency Code".AssistEdit();

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 280259
        PurchaseReturnOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 301110
        PurchaseReturnOrder."Re&lease".Invoke(); // Release
        PurchaseReturnOrder."Posting Date".SetValue(PurchaseReturnOrder."Posting Date".AsDate() + 1);

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // Bug 412765:
        PurchaseReturnOrder.Reopen.Invoke();
        PurchaseReturnOrder.Close();

        DeleteAllLinesFromPurchaseDocument(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader);

        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        PurchaseReturnOrder."Posting Date".SetValue(LibraryRandom.RandDate(5));

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRateMPH')]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderUpdateCurrrencyFactor()
    var
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        InvoiceDiscountPercent: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Blanket Order] [FCY]
        // [SCENARIO 280259] "Invoice Discount Amount" remains unchanged after Currency Factor updated on Purchase Return Order card page
        Initialize();

        CreatePurchaseHeaderWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order");

        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".SetValue(Round(PurchaseHeader.Amount / 3));

        InvoiceDiscountAmount := BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".AsDecimal();
        InvoiceDiscountPercent := BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".AsDecimal();
        Assert.AreNotEqual(0, InvoiceDiscountAmount, InvoiceDiscountAmountErr);
        Assert.AreNotEqual(0, InvoiceDiscountPercent, InvoiceDiscountPercentErr);

        LibraryVariableStorage.Enqueue(LibraryRandom.RandDecInRange(10, 20, 2));
        BlanketPurchaseOrder."Currency Code".AssistEdit();

        VerifyPurchaseHeaderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SQ_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Quote]
        // [SCENARIO 296939] Stan can change posistion on sales quote lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        Commit(); // It is important to COMMIT changes

        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesQuote.SalesLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Order]
        // [SCENARIO 296939] Stan can change posistion on sales order lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        Commit(); // It is important to COMMIT changes

        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesOrder.SalesLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SI_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Invoice]
        // [SCENARIO 296939] Stan can change posistion on sales invoice lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        Commit(); // It is important to COMMIT changes

        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        ClearLastError();
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesInvoice.SalesLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCrM_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Credit Memo]
        // [SCENARIO 296939] Stan can change posistion on sales credit memo lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo");
        Commit(); // It is important to COMMIT changes

        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");
        ClearLastError();
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesCreditMemo.SalesLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SRO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Return Order]
        // [SCENARIO 296939] Stan can change posistion on sales return order lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");
        Commit(); // It is important to COMMIT changes

        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(SalesReturnOrder.SalesLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SBO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales] [Blanket Order]
        // [SCENARIO 296939] Stan can change posistion on blanket sales order lines in case of active Calc. Invoice Discount
        Initialize();

        LibrarySales.SetCalcInvDiscount(true);

        CreateSalesDocumentWithCustInvDiscItemExtText(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order");
        Commit(); // It is important to COMMIT changes

        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        ClearLastError();
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(BlanketSalesOrder.SalesLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PQ_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Quote]
        // [SCENARIO 296939] Stan can change posistion on purchase quote lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote);

        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuote.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseQuote.PurchLines."No.".SetValue(Item."No.");
        PurchaseQuote.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseQuote.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseQuote.PurchLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Order]
        // [SCENARIO 296939] Stan can change posistion on purchase order lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(Item."No.");
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseOrder.PurchLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PI_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Invoice]
        // [SCENARIO 296939] Stan can change posistion on purchase invoice lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseInvoice.PurchLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCrM_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Credit Memo]
        // [SCENARIO 296939] Stan can change posistion on purchase credit memo lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");
        PurchaseCreditMemo.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PRO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Return Order]
        // [SCENARIO 296939] Stan can change posistion on purchase return order lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");

        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseReturnOrder.PurchLines."No.".SetValue(Item."No.");
        PurchaseReturnOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(PurchaseReturnOrder.PurchLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PBO_MoveNextLineAfterQuantityValidateCalcInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase] [Blanket Order]
        // [SCENARIO 296939] Stan can change posistion on blanket purchase order lines in case of active Calc. Invoice Discount
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);
        CreateItemWithExtendedText(Item);

        CreatePurchaseDocumentWithCustInvDiscItemExtText(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order");

        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        BlanketPurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        BlanketPurchaseOrder.PurchLines."No.".SetValue(Item."No.");
        BlanketPurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandIntInRange(2, 5));
        Commit(); // It is important to COMMIT changes
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandIntInRange(2, 5));

        Assert.IsTrue(BlanketPurchaseOrder.PurchLines.Next(), 'Stan must be able to go to next line');
        Assert.AreEqual('', GetLastErrorCallstack, 'Unexpected error has been thrown');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsUpdatesInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 378462] "Invoice Discount Amount" on Sales Order page is updated after it changed on Statistics page.
        Initialize();

        // [GIVEN] Sales Order with two Sales Lines with Unit Price = 5 and 10000.
        CreateSalesHeaderWithTwoLines(
            SalesHeader, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
            LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(10000, 20000));

        // [GIVEN] Sales Order is opened on Sales Order page.
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] "Invoice Discount Amount" is set to 10 on Statistics page opened from Sales Order page.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1, 2));
        SalesOrder.Statistics.Invoke();

        // [THEN] "Invoice Discount Amount" is equal to 10 on Sales Order page.
        SalesHeader.Find();
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(SalesHeader."Invoice Discount Value");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsUpdatesInvoiceDiscountAmountNM()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 378462] "Invoice Discount Amount" on Sales Order page is updated after it changed on Statistics page.
        Initialize();

        // [GIVEN] Sales Order with two Sales Lines with Unit Price = 5 and 10000.
        CreateSalesHeaderWithTwoLines(SalesHeader, SalesHeader."Document Type"::Order, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(10000, 20000));

        // [GIVEN] Sales Order is opened on Sales Order page.
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] "Invoice Discount Amount" is set to 10 on Statistics page opened from Sales Order page.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1, 2));
        SalesOrder.SalesOrderStatistics.Invoke();

        // [THEN] "Invoice Discount Amount" is equal to 10 on Sales Order page.
        SalesHeader.Find();
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(SalesHeader."Invoice Discount Value");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsUpdatesInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 378462] "Invoice Discount Amount" on Purchase Order page is updated after it changed on Statistics page.
        Initialize();

        // [GIVEN] Purchase Order with two Purchase Lines with Direct Unit Cost = 5 and 10000.
        CreatePurchaseHeaderWithTwoLines(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
            LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(10000, 20000));

        // [GIVEN] Purchase Order is opened on Purchase Order page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] "Invoice Discount Amount" is set to 10 on Statistics page opened from Purchase Order page.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1, 2));
        PurchaseOrder.Statistics.Invoke();

        // [THEN] "Invoice Discount Amount" is equal to 10 on Purchase Order page.
        PurchaseHeader.Find();
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(PurchaseHeader."Invoice Discount Value");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsUpdatesInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 378462] "Invoice Discount Amount" on Purchase Order page is updated after it changed on Statistics page.
        Initialize();

        // [GIVEN] Purchase Order with two Purchase Lines with Direct Unit Cost = 5 and 10000.
        CreatePurchaseHeaderWithTwoLines(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
            LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(10000, 20000));

        // [GIVEN] Purchase Order is opened on Purchase Order page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] "Invoice Discount Amount" is set to 10 on Statistics page opened from Purchase Order page.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1, 2));
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
        PurchaseOrder.Close();

        // [THEN] "Invoice Discount Amount" is equal to 10 on Purchase Order page.
        PurchaseHeader.Find();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines."Invoice Discount Amount".AssertEquals(PurchaseHeader."Invoice Discount Value");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesBlanketPurchaseOrderSubform()
    var
        BlanketPurchaseOrderTestPage: TestPage "Blanket Purchase Order";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Blanket Paurchase Order Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Blanket Purchase Order"
        BlanketPurchaseOrderTestPage.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        BlanketPurchaseOrderTestPage."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(BlanketPurchaseOrderTestPage.PurchLines.AmountBeforeDiscount.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(BlanketPurchaseOrderTestPage.PurchLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(BlanketPurchaseOrderTestPage.PurchLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(BlanketPurchaseOrderTestPage.PurchLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(BlanketPurchaseOrderTestPage.PurchLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesBlanketSalesOrderSubform()
    var
        BlanketSalesOrderTestPage: TestPage "Blanket Sales Order";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Blanket Sales Order Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Blanket Sales Order"
        BlanketSalesOrderTestPage.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        BlanketSalesOrderTestPage."Currency Code".SetValue(CurrencyCode);

        // [THEN] SubtotalExclVAT ends with '.000'
        Assert.IsTrue(BlanketSalesOrderTestPage.SalesLines.SubtotalExclVAT.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(BlanketSalesOrderTestPage.SalesLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(BlanketSalesOrderTestPage.SalesLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(BlanketSalesOrderTestPage.SalesLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(BlanketSalesOrderTestPage.SalesLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesPurchaseOrderSubform()
    var
        PurchaseOrder: TestPage "Purchase Order";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Purchase Order Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Purchase Order"
        PurchaseOrder.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        PurchaseOrder."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(PurchaseOrder.PurchLines.AmountBeforeDiscount.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(PurchaseOrder.PurchLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseOrder.PurchLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(PurchaseOrder.PurchLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseOrder.PurchLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesPurchaseQuoteSubform()
    var
        PurchaseQuote: TestPage "Purchase Quote";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Purchase Quote Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Purchase Quote"
        PurchaseQuote.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        PurchaseQuote."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(PurchaseQuote.PurchLines.AmountBeforeDiscount.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(PurchaseQuote.PurchLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseQuote.PurchLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(PurchaseQuote.PurchLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseQuote.PurchLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesPurchaseReturnOrderSubform()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Purchase Return Order Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Purchase Return Order"
        PurchaseReturnOrder.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        PurchaseReturnOrder."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(PurchaseReturnOrder.PurchLines.AmountBeforeDiscount.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseReturnOrder.PurchLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(PurchaseReturnOrder.PurchLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseReturnOrder.PurchLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesPurchaseCrMemoSubform()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Purchase Cr. Memo Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Purchase Credit Memo"
        PurchaseCreditMemo.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        PurchaseCreditMemo."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.AmountBeforeDiscount.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesPurchaseInvoiceSubform()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Purchase Invoice Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Purchase Invoice"
        PurchaseInvoice.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        PurchaseInvoice."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(PurchaseInvoice.PurchLines.AmountBeforeDiscount.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseInvoice.PurchLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(PurchaseInvoice.PurchLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(PurchaseInvoice.PurchLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesSalesCrMemoSubform()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Sales Cr. Memo Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Sales Credit Memo"
        SalesCreditMemo.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        SalesCreditMemo."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(SalesCreditMemo.SalesLines."TotalSalesLine.""Line Amount""".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(SalesCreditMemo.SalesLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(SalesCreditMemo.SalesLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(SalesCreditMemo.SalesLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(SalesCreditMemo.SalesLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesSalesInvoiceSubform()
    var
        SalesInvoice: TestPage "Sales Invoice";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Sales Invoice Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Sales Invoice"
        SalesInvoice.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        SalesInvoice."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(SalesInvoice.SalesLines."TotalSalesLine.""Line Amount""".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(SalesInvoice.SalesLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(SalesInvoice.SalesLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(SalesInvoice.SalesLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(SalesInvoice.SalesLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesSalesOrderSubform()
    var
        SalesOrder: TestPage "Sales Order";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Sales Order Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Sales Order"
        SalesOrder.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        SalesOrder."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(SalesOrder.SalesLines."TotalSalesLine.""Line Amount""".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(SalesOrder.SalesLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(SalesOrder.SalesLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(SalesOrder.SalesLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(SalesOrder.SalesLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesSalesQuoteSubform()
    var
        SalesQuote: TestPage "Sales Quote";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Sales Quote Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Sales Quote"
        SalesQuote.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        SalesQuote."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(SalesQuote.SalesLines."Subtotal Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(SalesQuote.SalesLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(SalesQuote.SalesLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(SalesQuote.SalesLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(SalesQuote.SalesLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalDecimalPlacesSalesReturnOrderSubform()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 388998] Count of decimals in totaling fields of "Sales Return Order Subform" must be equal to currency from header
        Initialize();

        // [GIVEN] Currency "C" with "Amount Decimal Places" = '3:3' and "Amount Rounding Precision" = '0.001'
        CurrencyCode := CreateCurrencyWithDecimalPlaces();

        // [GIVEN] Page "Sales Return Order"
        SalesReturnOrder.OpenNew();

        // [WHEN] Set "Currency Code" = "C"
        SalesReturnOrder."Currency Code".SetValue(CurrencyCode);

        // [THEN] AmountBeforeDiscount ends with '.000'
        Assert.IsTrue(SalesReturnOrder.SalesLines.SubtotalExclVAT.Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Invoice Discount Amount" ends with '.000'
        Assert.IsTrue(SalesReturnOrder.SalesLines."Invoice Discount Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Excl. VAT" ends with '.000'
        Assert.IsTrue(SalesReturnOrder.SalesLines."Total Amount Excl. VAT".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total VAT Amount" ends with '.000'
        Assert.IsTrue(SalesReturnOrder.SalesLines."Total VAT Amount".Value.EndsWith('.000'), WrongDecimalErr);

        // [THEN] "Total Amount Incl. VAT" ends with '.000'
        Assert.IsTrue(SalesReturnOrder.SalesLines."Total Amount Incl. VAT".Value.EndsWith('.000'), WrongDecimalErr);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsUpdateVATAmountModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesUpdateLineAmountAfterSettingVATDifferenceOnStatisticsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineGLAccount: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        MaxAllowedVATDifference: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [UI] [VAT] [Sales] [VAT Difference]
        // [SCENARIO 401242] "Amount Including VAT" of the sales line must consider "VAT Differrence" specified other document lines.

        Initialize();

        // [GIVEN] "VAT Difference" is allowed in setup
        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(5, 10);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Invoice with two lines having the same VAT Posting Groups.
        // [GIVEN] Line[1]. Amount = 100, "VAT %" = 25, "Amount Including VAT" = 125
        // [GIVEN] Line[1]. Amount = 200, "VAT %" = 25, "Amount Including VAT" = 250
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        CreateSalesLineWithVATPostingSetupAndAmount(
          SalesLineItem, SalesHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));
        CreateSalesLineWithVATPostingSetupAndAmount(
          SalesLineGLAccount, SalesHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] VAT Amount Increased by 3 on Statistics page
        // [GIVEN] Line[1]."Amount Including VAT" = 151, "VAT Differene" = 1
        // [GIVEN] Line[1]."Amount Including VAT" = 252, "VAT Differene" = 2
        LibraryVariableStorage.Enqueue(Round(MaxAllowedVATDifference / 3));

        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.Filter.SetFilter("No.", SalesHeader."No.");

        ExpectedVATAmount :=
          Round((SalesLineItem.CalcLineAmount() + SalesLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          SalesLineItem."VAT Difference" + SalesLineGLAccount."VAT Difference";
        SalesInvoicePage.SalesLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        SalesInvoicePage.Statistics.Invoke();

        SalesLineItem.Find();
        SalesLineItem.TestField("VAT Difference");

        SalesLineGLAccount.Find();
        SalesLineGLAccount.TestField("VAT Difference");

        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 3 = 73
        SalesInvoicePage.SalesLines.Last();
        ExpectedVATAmount :=
          Round((SalesLineItem.CalcLineAmount() + SalesLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          SalesLineItem."VAT Difference" + SalesLineGLAccount."VAT Difference";
        SalesInvoicePage.SalesLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        // [WHEN] User updates "Unit Price" on the second line
        SalesInvoicePage.SalesLines."Unit Price".SetValue(SalesLineGLAccount."Unit Price" + 1);
        SalesInvoicePage.SalesLines.Previous();
        SalesInvoicePage.SalesLines.Next();

        // [THEN] "VAT Diferrence" and "Amount Including VAT" have been reset.
        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 1 = 71
        SalesLineItem.Find();
        SalesLineItem.TestField("VAT Difference");

        SalesLineGLAccount.Find();
        SalesLineGLAccount.TestField(
          "Amount Including VAT",
          Round(SalesLineGLAccount.CalcLineAmount() * (1 + VATPostingSetup."VAT %" / 100)));
        SalesLineGLAccount.TestField("VAT Difference", 0);

        ExpectedVATAmount :=
          Round((SalesLineItem.CalcLineAmount() + SalesLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          SalesLineItem."VAT Difference" + SalesLineGLAccount."VAT Difference";
        SalesInvoicePage.SalesLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        LibraryVariableStorage.AssertEmpty();
    end;
#endif
    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsUpdateVATAmountPageHandler')]
    [Scope('OnPrem')]
    procedure SalesUpdateLineAmountAfterSettingVATDifferenceOnSalesStatisticsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineGLAccount: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        MaxAllowedVATDifference: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [UI] [VAT] [Sales] [VAT Difference]
        // [SCENARIO 401242] "Amount Including VAT" of the sales line must consider "VAT Differrence" specified other document lines.

        Initialize();

        // [GIVEN] "VAT Difference" is allowed in setup
        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(5, 10);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Invoice with two lines having the same VAT Posting Groups.
        // [GIVEN] Line[1]. Amount = 100, "VAT %" = 25, "Amount Including VAT" = 125
        // [GIVEN] Line[1]. Amount = 200, "VAT %" = 25, "Amount Including VAT" = 250
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        CreateSalesLineWithVATPostingSetupAndAmount(
          SalesLineItem, SalesHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));
        CreateSalesLineWithVATPostingSetupAndAmount(
          SalesLineGLAccount, SalesHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] VAT Amount Increased by 3 on Statistics page
        // [GIVEN] Line[1]."Amount Including VAT" = 151, "VAT Differene" = 1
        // [GIVEN] Line[1]."Amount Including VAT" = 252, "VAT Differene" = 2
        LibraryVariableStorage.Enqueue(Round(MaxAllowedVATDifference / 3));

        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.Filter.SetFilter("No.", SalesHeader."No.");

        ExpectedVATAmount :=
          Round((SalesLineItem.CalcLineAmount() + SalesLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          SalesLineItem."VAT Difference" + SalesLineGLAccount."VAT Difference";
        SalesInvoicePage.SalesLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        SalesInvoicePage.SalesStatistics.Invoke();

        SalesLineItem.Find();
        SalesLineItem.TestField("VAT Difference");

        SalesLineGLAccount.Find();
        SalesLineGLAccount.TestField("VAT Difference");

        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 3 = 73
        SalesInvoicePage.SalesLines.Last();
        ExpectedVATAmount :=
          Round((SalesLineItem.CalcLineAmount() + SalesLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          SalesLineItem."VAT Difference" + SalesLineGLAccount."VAT Difference";
        SalesInvoicePage.SalesLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        // [WHEN] User updates "Unit Price" on the second line
        SalesInvoicePage.SalesLines."Unit Price".SetValue(SalesLineGLAccount."Unit Price" + 1);
        SalesInvoicePage.SalesLines.Previous();
        SalesInvoicePage.SalesLines.Next();

        // [THEN] "VAT Diferrence" and "Amount Including VAT" have been reset.
        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 1 = 71
        SalesLineItem.Find();
        SalesLineItem.TestField("VAT Difference");

        SalesLineGLAccount.Find();
        SalesLineGLAccount.TestField(
          "Amount Including VAT",
          Round(SalesLineGLAccount.CalcLineAmount() * (1 + VATPostingSetup."VAT %" / 100)));
        SalesLineGLAccount.TestField("VAT Difference", 0);

        ExpectedVATAmount :=
          Round((SalesLineItem.CalcLineAmount() + SalesLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          SalesLineItem."VAT Difference" + SalesLineGLAccount."VAT Difference";
        SalesInvoicePage.SalesLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatisticsUpdateVATAmountModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseUpdateLineAmountAfterSettingVATDifferenceOnStatisticsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineGLAccount: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxAllowedVATDifference: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [UI] [VAT] [Purchase] [VAT Difference]
        // [SCENARIO 401242] "Amount Including VAT" of the purchase line must consider "VAT Differrence" specified other document lines.

        Initialize();

        // [GIVEN] "VAT Difference" is allowed in setup
        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(5, 10);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Invoice with two lines having the same VAT Posting Groups.
        // [GIVEN] Line[1]. Amount = 100, "VAT %" = 25, "Amount Including VAT" = 125
        // [GIVEN] Line[1]. Amount = 200, "VAT %" = 25, "Amount Including VAT" = 250
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        CreatePurchaseLineWithVATPostingSetupAndAmount(
          PurchaseLineItem, PurchaseHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));
        CreatePurchaseLineWithVATPostingSetupAndAmount(
          PurchaseLineGLAccount, PurchaseHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] VAT Amount Increased by 3 on Statistics page
        // [GIVEN] Line[1]."Amount Including VAT" = 151, "VAT Differene" = 1
        // [GIVEN] Line[1]."Amount Including VAT" = 252, "VAT Differene" = 2
        LibraryVariableStorage.Enqueue(Round(MaxAllowedVATDifference / 3));

        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");

        ExpectedVATAmount :=
          Round((PurchaseLineItem.CalcLineAmount() + PurchaseLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          PurchaseLineItem."VAT Difference" + PurchaseLineGLAccount."VAT Difference";
        PurchaseInvoicePage.PurchLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        PurchaseInvoicePage.Statistics.Invoke();

        PurchaseLineItem.Find();
        PurchaseLineItem.TestField("VAT Difference");

        PurchaseLineGLAccount.Find();
        PurchaseLineGLAccount.TestField("VAT Difference");

        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 3 = 73
        PurchaseInvoicePage.PurchLines.Last();
        ExpectedVATAmount :=
          Round((PurchaseLineItem.CalcLineAmount() + PurchaseLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          PurchaseLineItem."VAT Difference" + PurchaseLineGLAccount."VAT Difference";
        PurchaseInvoicePage.PurchLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        // [WHEN] User updates "Unit Price" on the second line
        PurchaseInvoicePage.PurchLines."Direct Unit Cost".SetValue(PurchaseLineGLAccount."Direct Unit Cost" + 1);
        PurchaseInvoicePage.PurchLines.Previous();
        PurchaseInvoicePage.PurchLines.Next();

        // [THEN] "VAT Diferrence" and "Amount Including VAT" have been reset.
        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 1 = 71
        PurchaseLineItem.Find();
        PurchaseLineItem.TestField("VAT Difference");

        PurchaseLineGLAccount.Find();
        PurchaseLineGLAccount.TestField(
          "Amount Including VAT",
          Round(PurchaseLineGLAccount.CalcLineAmount() * (1 + VATPostingSetup."VAT %" / 100)));
        PurchaseLineGLAccount.TestField("VAT Difference", 0);

        ExpectedVATAmount :=
          Round((PurchaseLineItem.CalcLineAmount() + PurchaseLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          PurchaseLineItem."VAT Difference" + PurchaseLineGLAccount."VAT Difference";
        PurchaseInvoicePage.PurchLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        LibraryVariableStorage.AssertEmpty();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseInvoiceStatisticsUpdateVATAmountPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseUpdateLineAmountAfterSettingVATDifferenceOnPurchaseStatisticsPage()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineGLAccount: Record "Purchase Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        MaxAllowedVATDifference: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [UI] [VAT] [Purchase] [VAT Difference]
        // [SCENARIO 401242] "Amount Including VAT" of the purchase line must consider "VAT Differrence" specified other document lines.

        Initialize();

        // [GIVEN] "VAT Difference" is allowed in setup
        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(5, 10);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Invoice with two lines having the same VAT Posting Groups.
        // [GIVEN] Line[1]. Amount = 100, "VAT %" = 25, "Amount Including VAT" = 125
        // [GIVEN] Line[1]. Amount = 200, "VAT %" = 25, "Amount Including VAT" = 250
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        CreatePurchaseLineWithVATPostingSetupAndAmount(
          PurchaseLineItem, PurchaseHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));
        CreatePurchaseLineWithVATPostingSetupAndAmount(
          PurchaseLineGLAccount, PurchaseHeader, VATPostingSetup, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] VAT Amount Increased by 3 on Statistics page
        // [GIVEN] Line[1]."Amount Including VAT" = 151, "VAT Differene" = 1
        // [GIVEN] Line[1]."Amount Including VAT" = 252, "VAT Differene" = 2
        LibraryVariableStorage.Enqueue(Round(MaxAllowedVATDifference / 3));

        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");

        ExpectedVATAmount :=
          Round((PurchaseLineItem.CalcLineAmount() + PurchaseLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          PurchaseLineItem."VAT Difference" + PurchaseLineGLAccount."VAT Difference";
        PurchaseInvoicePage.PurchLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        PurchaseLineItem.Find();
        PurchaseLineItem.TestField("VAT Difference");

        PurchaseLineGLAccount.Find();
        PurchaseLineGLAccount.TestField("VAT Difference");

        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 3 = 73
        PurchaseInvoicePage.PurchLines.Last();
        ExpectedVATAmount :=
          Round((PurchaseLineItem.CalcLineAmount() + PurchaseLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          PurchaseLineItem."VAT Difference" + PurchaseLineGLAccount."VAT Difference";
        PurchaseInvoicePage.PurchLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        // [WHEN] User updates "Unit Price" on the second line
        PurchaseInvoicePage.PurchLines."Direct Unit Cost".SetValue(PurchaseLineGLAccount."Direct Unit Cost" + 1);
        PurchaseInvoicePage.PurchLines.Previous();
        PurchaseInvoicePage.PurchLines.Next();

        // [THEN] "VAT Diferrence" and "Amount Including VAT" have been reset.
        // [GIVEN] "Total VAT Amount" on the document card = 25 + 50 + 1 = 71
        PurchaseLineItem.Find();
        PurchaseLineItem.TestField("VAT Difference");

        PurchaseLineGLAccount.Find();
        PurchaseLineGLAccount.TestField(
          "Amount Including VAT",
          Round(PurchaseLineGLAccount.CalcLineAmount() * (1 + VATPostingSetup."VAT %" / 100)));
        PurchaseLineGLAccount.TestField("VAT Difference", 0);

        ExpectedVATAmount :=
          Round((PurchaseLineItem.CalcLineAmount() + PurchaseLineGLAccount.CalcLineAmount()) * VATPostingSetup."VAT %" / 100) +
          PurchaseLineItem."VAT Difference" + PurchaseLineGLAccount."VAT Difference";
        PurchaseInvoicePage.PurchLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteInvoiceDiscountEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 404794] "Invoice Discount Amount" on Sales Quote page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Sales Quote is opened on Sales Quote page.
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        SalesQuote.Release.Invoke();
        Assert.IsFalse(SalesQuote.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(SalesQuote.SalesLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Sales Quote
        SalesQuote.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(SalesQuote.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(SalesQuote.SalesLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceDiscountEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 404794] "Invoice Discount Amount" on Sales Order page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Sales Order is opened on Sales Order page.
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        SalesOrder.Release.Invoke();
        Assert.IsFalse(SalesOrder.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(SalesOrder.SalesLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Sales Order
        SalesOrder.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(SalesOrder.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(SalesOrder.SalesLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceInvoiceDiscountEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 404794] "Invoice Discount Amount" on Sales Invoice page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Sales Invoice is opened on Sales Invoice page.
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        SalesInvoice.Release.Invoke();
        Assert.IsFalse(SalesInvoice.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(SalesInvoice.SalesLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Sales Invoice
        SalesInvoice.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(SalesInvoice.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(SalesInvoice.SalesLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoInvoiceDiscountEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 404794] "Invoice Discount Amount" on Sales Credit Memo page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Sales Credit Memo is opened on Sales Credit Memo page.
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        SalesCreditMemo.Release.Invoke();
        Assert.IsFalse(SalesCreditMemo.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(SalesCreditMemo.SalesLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Sales Credit Memo
        SalesCreditMemo.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(SalesCreditMemo.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(SalesCreditMemo.SalesLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderInvoiceDiscountEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 404794] "Invoice Discount Amount" on Blanket Sales Order page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Blanket Sales Order is opened on Blanket Sales Order page.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        BlanketSalesOrder.Release.Invoke();
        Assert.IsFalse(BlanketSalesOrder.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Blanket Sales Order
        BlanketSalesOrder.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(BlanketSalesOrder.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRetuurnOrderInvoiceDiscountEditable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Sales]
        // [SCENARIO 404794] "Invoice Discount Amount" on Sales Return Order page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Sales Return Order is opened on Sales Return Order page.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        SalesReturnOrder.Release.Invoke();
        Assert.IsFalse(SalesReturnOrder.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(SalesReturnOrder.SalesLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Sales Return Order
        SalesReturnOrder.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(SalesReturnOrder.SalesLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(SalesReturnOrder.SalesLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteInvoiceDiscountEditable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 404794] "Invoice Discount Amount" on Purchase Quote page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Purchase Quote is opened on Purchase Quote page.
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        PurchaseQuote.Release.Invoke();
        Assert.IsFalse(PurchaseQuote.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(PurchaseQuote.PurchLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Purchase Quote
        PurchaseQuote.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(PurchaseQuote.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(PurchaseQuote.PurchLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInvoiceDiscountEditable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 404794] "Invoice Discount Amount" on Purchase Order page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Purchase Order is opened on Purchase Order page.
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        PurchaseOrder.Release.Invoke();
        Assert.IsFalse(PurchaseOrder.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(PurchaseOrder.PurchLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Purchase Order
        PurchaseOrder.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(PurchaseOrder.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(PurchaseOrder.PurchLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceInvoiceDiscountEditable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 404794] "Invoice Discount Amount" on Purchase Invoice page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Purchase Invoice is opened on Purchase Invoice page.
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        PurchaseInvoice."Re&lease".Invoke();
        Assert.IsFalse(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.Editable(), '');
        Assert.IsFalse(PurchaseInvoice.PurchLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Purchase Invoice
        PurchaseInvoice.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(PurchaseInvoice.PurchLines.InvoiceDiscountAmount.Editable(), '');
        Assert.IsTrue(PurchaseInvoice.PurchLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoInvoiceDiscountEditable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 404794] "Invoice Discount Amount" on Purchase Credit Memo page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Purchase Credit Memo is opened on Purchase Credit Memo page.
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        PurchaseCreditMemo.Release.Invoke();
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Purchase Credit Memo
        PurchaseCreditMemo.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' is editabe and 'Invoice Disc. Pct.' is not editable (false property)
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderInvoiceDiscountEditable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 404794] "Invoice Discount Amount" on Blanket Purchase Order page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Blanket Purchase Order is opened on Blanket Purchase Order page.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        BlanketPurchaseOrder.Release.Invoke();
        Assert.IsFalse(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Purchase Quote
        BlanketPurchaseOrder.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(BlanketPurchaseOrder.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(BlanketPurchaseOrder.PurchLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderInvoiceDiscountEditable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI] [Invoice Discount] [Purchase]
        // [SCENARIO 404794] "Invoice Discount Amount" on Purchase Return Order page is Editable with Status = 'Open'
        Initialize();

        // [GIVEN] Purchase Return Order is opened on Purchase Return Order page.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable for released document
        PurchaseReturnOrder."Re&lease".Invoke();
        Assert.IsFalse(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsFalse(PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".Editable(), '');

        // [WHEN] Reopen the Purchase Return Order
        PurchaseReturnOrder.Reopen.Invoke();

        // [THEN] 'Invoice Discount Amount' and 'Invoice Disc. Pct.' both editable
        Assert.IsTrue(PurchaseReturnOrder.PurchLines."Invoice Discount Amount".Editable(), '');
        Assert.IsTrue(PurchaseReturnOrder.PurchLines."Invoice Disc. Pct.".Editable(), '');
    end;

    [Test]
    [HandlerFunctions('InvoiceDiscountMessageHandler')]
    procedure SalesOrderRoundingShowsMessage()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 572752] Sales Order rounding the Invoice discount Percentage and getting modified value after message
        Initialize();

        // [GIVEN] Create sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create Sales Line with value 60.61 which help to get rounding value of Invoice Discount Percentage
        CreateSalesLineWithAmount(SalesHeader, 1, 60.61);

        // [GIVEN] Open the Sales Order Page
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Set the value of Invoice Discount Percentage to 12
        SalesOrder.SalesLines."Invoice Disc. Pct.".SetValue(LibraryRandom.RandIntInRange(12, 12));

        // [THEN] Verify the value has been rounded to near 12 and message handler page shows same message of rounding
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoTotalsCalculatedAfterGetPostedDocToReverse()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustomerNo: Code[20];
        ExpectedTotalExclVAT: Decimal;
        ExpectedTotalInclVAT: Decimal;
    begin
        // [SCENARIO 603839] Verify totals are automatically calculated when using "Get Posted Document to Reverse" action
        Initialize();

        // [GIVEN] Create and post a Sales Invoice
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLineWithItemAndQuantity(SalesHeader, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(1, 10), LibraryRandom.RandDecInRange(100, 1000, 2));

        // [GIVEN] Calculate expected totals (assuming no VAT for simplicity)
        SalesHeader.CalcFields("Amount Including VAT", "Amount");
        ExpectedTotalExclVAT := SalesHeader.Amount;
        ExpectedTotalInclVAT := SalesHeader."Amount Including VAT";

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create a Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Open Sales Credit Memo page and use "Get Posted Document to Reverse"
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");

        LibraryVariableStorage.Enqueue(1); // PostedInvoices option
        SalesCreditMemo.GetPostedDocumentLinesToReverse.Invoke();

        // [THEN] Totals are automatically calculated and displayed correctly
        Assert.AreEqual(ExpectedTotalExclVAT, SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
            VATAmountErr);
        Assert.AreEqual(ExpectedTotalInclVAT, SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
            VATAmountErr);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Document Totals Pages");

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Document Totals Pages");

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Document Totals Pages");
    end;

    local procedure AddInvoiceDiscToCustomer(Customer: Record Customer; MinimumAmount: Decimal; Percentage: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", MinimumAmount);
        CustInvoiceDisc.Validate("Discount %", Percentage);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        AddInvoiceDiscToCustomer(
          Customer, LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));
    end;

    local procedure AddInvoiceDiscToVendor(Vendor: Record Vendor; MinimumAmount: Decimal; Percentage: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", MinimumAmount);
        VendorInvoiceDisc.Validate("Discount %", Percentage);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        AddInvoiceDiscToVendor(
          Vendor, LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header")
    begin
        CreateSalesLineWithAmount(SalesHeader, 1, LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseLineWithAmount(PurchaseHeader, 1, LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreateSalesLineWithAmount(var SalesHeader: Record "Sales Header"; LineQuantity: Decimal; LinePrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LineQuantity);
        SalesLine.Validate("Unit Price", LinePrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithAmount(var PurchaseHeader: Record "Purchase Header"; LineQuantity: Decimal; LineCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LineQuantity);
        PurchaseLine.Validate("Direct Unit Cost", LineCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemWithExtendedText(var Item: Record Item)
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        Item.Modify(true);

        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateGUID());
        ExtendedTextLine.Modify(true);
    end;

    local procedure CreateSalesHeaderWithCurrency(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());

        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate(
          "Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5)));
        SalesHeader.SetHideValidationDialog(false);
        SalesHeader.Modify(true);

        CreateSalesLineWithAmount(SalesHeader, 1, LibraryRandom.RandDecInRange(10, 20, 2));

        SalesHeader.CalcFields(Amount);
    end;

    local procedure CreateSalesHeaderWithTwoLines(var SalesHeader: Record "Sales Header"; Type: Enum "Sales Document Type"; Qty1: Decimal; UnitPrice1: Decimal; Qty2: Decimal; UnitPrice2: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, Type, LibrarySales.CreateCustomerNo());

        CreateSalesLineWithAmount(SalesHeader, Qty1, UnitPrice1);
        CreateSalesLineWithAmount(SalesHeader, Qty2, UnitPrice2);
    end;

    local procedure CreatePurchaseHeaderWithCurrency(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());

        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate(
          "Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandInt(5), LibraryRandom.RandInt(5)));
        PurchaseHeader.SetHideValidationDialog(false);
        PurchaseHeader.Modify(true);

        CreatePurchaseLineWithAmount(PurchaseHeader, 1, LibraryRandom.RandDecInRange(10, 20, 2));

        PurchaseHeader.CalcFields(Amount);
    end;

    local procedure CreatePurchaseHeaderWithTwoLines(var PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Document type"; Qty1: Decimal; UnitPrice1: Decimal; Qty2: Decimal; UnitPrice2: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, Type, LibraryPurchase.CreateVendorNo());

        CreatePurchaseLineWithAmount(PurchaseHeader, Qty1, UnitPrice1);
        CreatePurchaseLineWithAmount(PurchaseHeader, Qty2, UnitPrice2);
    end;

    local procedure CreateSalesLineWithVATPostingSetupAndAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithVATPostingSetupAndAmount(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithCustInvDiscItemExtText(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateCustomerWithDiscount(Customer);
        CreateItemWithExtendedText(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
    end;

    local procedure CreatePurchaseDocumentWithCustInvDiscItemExtText(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        CreateVendorWithDiscount(Vendor);
        CreateItemWithExtendedText(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
    end;

    local procedure CreateCurrencyWithDecimalPlaces(): Code[10]
    var
        Currency: Record Currency;
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        Currency.Get(CurrencyCode);
        Currency.Validate("Amount Decimal Places", '3:3');
        Currency.Validate("Amount Rounding Precision", 0.001);
        Currency.Modify(true);
        exit(CurrencyCode);
    end;

    local procedure CreateSalesLineWithItemAndQuantity(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LineQuantity: Decimal; LinePrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LineQuantity);
        SalesLine.Validate("Unit Price", LinePrice);
        SalesLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeExchangeRateMPH(var ChangeExchangeRate: TestPage "Change Exchange Rate")
    begin
        ChangeExchangeRate.CurrentExchRate.SetValue(LibraryVariableStorage.DequeueDecimal());
        ChangeExchangeRate.OK().Invoke();
    end;

    local procedure DeleteAllLinesFromSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Find();

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.DeleteAll(true);

        SalesHeader.Find();
    end;

    local procedure DeleteAllLinesFromPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.Find();

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.DeleteAll(true);

        PurchaseHeader.Find();
    end;

    local procedure VerifySalesHeaderInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal)
    begin
        SalesHeader.CalcFields("Invoice Discount Amount");
        SalesHeader.TestField("Invoice Discount Amount", InvoiceDiscountAmount);
    end;

    local procedure VerifyPurchaseHeaderInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; InvoiceDiscountAmount: Decimal)
    begin
        PurchaseHeader.CalcFields("Invoice Discount Amount");
        PurchaseHeader.TestField("Invoice Discount Amount", InvoiceDiscountAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(MessageText: Text[1024])
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStatistics.OK().Invoke();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsUpdateVATAmountModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        SalesStatistics.SubForm.Last();
        SalesStatistics.SubForm."VAT Amount".SetValue(
          SalesStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStatistics.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsUpdateVATAmountPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        SalesStatistics.SubForm.Last();
        SalesStatistics.SubForm."VAT Amount".SetValue(SalesStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsUpdateVATAmountModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        PurchaseStatistics.SubForm.Last();
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsUpdateVATAmountPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        PurchaseStatistics.SubForm.Last();
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal());
        PurchaseOrderStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_General.SetValue(LibraryVariableStorage.DequeueDecimal());
        PurchaseOrderStatistics.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure InvoiceDiscountMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(InvoiceDiscountPerRoundingMsg, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Return Receipts"));
            1:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
            2:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Shipments"));
            3:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Cr. Memos"));
        end;
        PostedSalesDocumentLines.OK().Invoke();
    end;
}
