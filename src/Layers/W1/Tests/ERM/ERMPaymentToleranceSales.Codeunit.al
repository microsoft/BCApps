codeunit 134017 "ERM Payment Tolerance Sales"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3 %4 %5.';
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithLCY()
    var
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124094,124095.
        // Check Customer Ledger Entry for Payment Tolerance after posting Sales Invoice without Currency.

        // Create and Post Sales Invoice without Currency.
        DocumentNo := CreateAndPostSalesDocument('', "Sales Document Type"::Invoice);

        // Verify: Verify Customer Ledger Entry Amount.
        ExpectedPmtTolAmount := CalcPaymentTolInvoiceLCY(DocumentNo);
        VerifyMaxPaymentTolInvoice(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithLCY()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124087,124088.
        // Check Customer Ledger Entry for Payment Tolerance after posting Sales Credit Memo without Currency.

        // Create and Post Sales Credit Memo without Currency.
        DocumentNo := CreateAndPostSalesDocument('', "Sales Document Type"::"Credit Memo");

        // Verify: Verify Customer Ledger Entry Amount.
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        VerifyCustomerLedgerEntry(SalesCrMemoHeader."Amount Including VAT", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFCY()
    var
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124094,124095.
        // Check Customer Ledger Entry for Payment Tolerance after posting Sales Invoice with Currency.

        // Create and Post Sales Invoice with Currency.
        DocumentNo := CreateAndPostSalesDocument(CreateCurrency(), "Sales Document Type"::Invoice);

        // Verify: Verify Customer Ledger Entry Amount.
        ExpectedPmtTolAmount := CalcPaymentTolInvoiceFCY(DocumentNo);
        VerifyMaxPaymentTolInvoice(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithFCY()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124087,124088.
        // Check Customer Ledger Entry  for Payment Tolerance after posting Sales Credit Memo with Currency.

        // Create and Post Sales Credit Memo with Currency.
        DocumentNo := CreateAndPostSalesDocument(CreateCurrency(), "Sales Document Type"::"Credit Memo");

        // Verify: Verify Customer Ledger Entry Amount.
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        VerifyCustomerLedgerEntry(SalesCrMemoHeader."Amount Including VAT", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocument()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        SalesInvoiceNo: Code[20];
    begin
        // Covers Test Case 124089.
        // Check Customer Ledger Entry for Payment Tolerance after posting Sales Credit Memo and Copy Document.

        // Setup: Update General ledger Setup and Create and Post Sales Invoice.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        CreateSalesDocument(SalesHeader, '', SalesHeader."Document Type"::Invoice);
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Insert(true);

        // Exercise: Create and Post Sales Credit Memo after Copy Document with Document Type Posted Invoice.
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, true, true);
        SalesHeader.SetRange("Applies-to Doc. No.", SalesInvoiceNo);
        SalesHeader.FindFirst();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Max Payment Tolerance is zero for Credit Memo applied to Invoice.
        VerifyMaxPaymentTolCreditMemo(DocumentNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocumentLineOnly()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        SalesInvoiceNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124090.
        // Check Customer Ledger Entry for Payment Tolerance after posting Sales Credit Memo and Copy Document with Only Line.

        // Setup: Update General Ledger Setup and Create and Post Sales invoice and take a Random quantity.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5)); // Use Random value for Payment Discount.
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // Exercise: Create and Post Sales Credit Memo after Copy Document with Document Type Posted Invoice.
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, false, true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Max Payment Tolerance field in Customer Ledger Entry.
        ExpectedPmtTolAmount := CalcPaymentTolCreditMemoLCY(DocumentNo);
        VerifyMaxPaymentTolCreditMemo(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocumentOpenInv()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124091.
        // Check Customer Ledger Entry for Payment Tolerance after posting Sales Credit Memo and Copy Document with Document Type Invoice.

        // Setup: Update General Ledger Setup and Create Sales Invoice and Insert new record with Document Type Credit memo.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        CreateSalesDocument(SalesHeader, '', SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5)); // Use Random value for Payment Discount.
        SalesHeader.Modify(true);
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Insert(true);

        // Exercise: Create and Post Sales Credit Memo after Copy Document with Document Type Invoice.
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::Invoice, SalesHeader."No.", true, true);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        SalesHeader.FindFirst();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Max Payment Tolerance field in Customer Ledger Entry.
        ExpectedPmtTolAmount := CalcPaymentTolCreditMemoLCY(DocumentNo);
        VerifyMaxPaymentTolCreditMemo(DocumentNo, ExpectedPmtTolAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Tolerance Sales");
        LibrarySetupStorage.Restore();
        ExecuteUIHandler();  // This function required for confirmation message to appear always.

        // Setup demo data.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance Sales");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance Sales");
    end;

    local procedure CreateAndPostSalesDocument(CurrencyCode: Code[10]; DocType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and Create Sales Document.
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        CreateSalesDocument(SalesHeader, CurrencyCode, DocType);

        // Exercise: Post Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(DocumentNo);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        // Use Random value for Payment Tolerance and Max Payment Tolerance Amount.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Payment Tolerance %", LibraryRandom.RandInt(5));
        Currency.Validate("Max. Payment Tolerance Amount", LibraryRandom.RandInt(5));
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        // Find Payment Terms Code and Update.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Validate("Block Payment Tolerance", false);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        // Price should be small enough to not make a document exceed Max. Payment Tolerance
        Item.Validate("Unit Price", LibraryRandom.RandInt(7));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        // Use Counter for Creating Multiple Sales Lines with Random Quantity.
        for Counter := 1 to LibraryRandom.RandInt(3) do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(3));
            if DocumentType = SalesLine."Document Type"::"Credit Memo" then begin
                SalesLine.Validate("Qty. to Ship", 0); // Quantity to ship must be 0 for Sales Credit Memo.
                SalesLine.Modify(true);
            end;
        end;
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
    end;

    local procedure CalcPaymentTolInvoiceFCY(DocumentNo: Code[20]): Decimal
    var
        Currency: Record Currency;
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Currency.Get(SalesInvoiceHeader."Currency Code");
        exit(SalesInvoiceHeader."Amount Including VAT" * Currency."Payment Tolerance %" / 100);
    end;

    local procedure CalcPaymentTolInvoiceLCY(DocumentNo: Code[20]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        GeneralLedgerSetup.Get();
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure CalcPaymentTolCreditMemoLCY(DocumentNo: Code[20]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        GeneralLedgerSetup.Get();
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.CalcFields("Amount Including VAT");
        exit(SalesCrMemoHeader."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure VerifyCustomerLedgerEntry(Amount: Decimal; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindCustomerLedgerEntry(CustLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(-Amount, CustLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption(),
            CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    local procedure VerifyMaxPaymentTolInvoice(DocumentNo: Code[20]; ExpectedPmtTolAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindCustomerLedgerEntry(CustLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(ExpectedPmtTolAmount, CustLedgerEntry."Max. Payment Tolerance",
          GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, CustLedgerEntry.FieldCaption(Amount),
            ExpectedPmtTolAmount, CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    local procedure VerifyMaxPaymentTolCreditMemo(DocumentNo: Code[20]; ExpectedPmtTolAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindCustomerLedgerEntry(CustLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(-ExpectedPmtTolAmount, CustLedgerEntry."Max. Payment Tolerance",
          GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, CustLedgerEntry.FieldCaption(Amount),
            ExpectedPmtTolAmount, CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

