codeunit 134078 "ERM Currency With Ledger Entry"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Ledger Entry] [Currency Code]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        CurrencyCodeError: Label 'Currency code must be %1.';
        AmountErrorMessage: Label '%1 must be %2 in %3.';
        DocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoAndVendorLedgerEntry()
    begin
        // Covers documents TC_ID=5296 and 5303.

        // Check that Vendor Ledger Entry has same Currency Code and Amount after Posting Purchase Credit Memo.
        CreateAndVerifyLedgerEntry(true, DocumentType::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAndVendorLedgerEntry()
    begin
        // Covers documents TC_ID=5297 and 5305.

        // Check that Vendor Ledger Entry has same Currency Code and Amount after Posting Purchase Invoice.
        CreateAndVerifyLedgerEntry(true, DocumentType::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OrderAndVendorLedgerEntry()
    begin
        // Covers documents TC_ID=5298 and 5307.

        // Check that Vendor Ledger Entry has same Currency Code and Amount after Posting Purchase Order.
        CreateAndVerifyLedgerEntry(true, DocumentType::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCustomerLedgerEntry()
    begin
        // Covers documents TC_ID=5299 and 5309.

        // Check that Customer Ledger Entry has same Currency Code and Amount after Posting Sales Credit Memo.
        CreateAndVerifyLedgerEntry(false, DocumentType::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAndCustomerLedgerEntry()
    begin
        // Covers documents TC_ID=5300 and 5311.

        // Check that Customer Ledger Entry has same Currency Code and Amount after Posting Sales Invoice.
        CreateAndVerifyLedgerEntry(false, DocumentType::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OrderAndCustomerLedgerEntry()
    begin
        // Covers documents TC_ID=5301 and 5313.

        // Check that Customer Ledger Entry has same Currency Code and Amount after Posting Sales Order.
        CreateAndVerifyLedgerEntry(false, DocumentType::Order);
    end;

    local procedure CreateAndVerifyLedgerEntry(PurchaseDocument: Boolean; DocType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        PostedInvoiceNo: Code[20];
        TotalAmount: Decimal;
    begin
        // Setup.
        Initialize();

        if PurchaseDocument then begin
            // Setup: Create Currency and Purchase Document as per the option selected after release.
            CreatePurchaseDocument(PurchaseHeader, CreateCurrencyAndExchangeRate(), "Purchase Document Type".FromInteger(DocType));
            LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
            PurchaseHeader.CalcFields("Amount Including VAT");
            TotalAmount := PurchaseHeader."Amount Including VAT";

            // Exercise: Post Purchase Document.
            PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

            // Verify: Check that Vendor Ledger Entry for Purchase Document has same Currency Code and Amount Posted.
            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
                VerifyVendorLedgerEntry(PostedInvoiceNo, PurchaseHeader."Currency Code", TotalAmount)
            else
                VerifyVendorLedgerEntry(PostedInvoiceNo, PurchaseHeader."Currency Code", -TotalAmount);
        end else begin
            // Setup: Create Currency and Sales Document as per the option selected after release.
            CreateSalesDocument(SalesHeader, CreateCurrencyAndExchangeRate(), "Purchase Document Type".FromInteger(DocType));
            LibrarySales.ReleaseSalesDocument(SalesHeader);
            SalesHeader.CalcFields("Amount Including VAT");
            TotalAmount := SalesHeader."Amount Including VAT";

            // Exercise: Post Sales Document.
            PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

            // Verify: Check that Customer Ledger Entry for Sales Document has same Currency Code and Amount Posted.
            if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                VerifyCustomerLedgerEntry(PostedInvoiceNo, SalesHeader."Currency Code", -TotalAmount)
            else
                VerifyCustomerLedgerEntry(PostedInvoiceNo, SalesHeader."Currency Code", TotalAmount);
        end;
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Currency With Ledger Entry");
        ExecuteUIHandler();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Currency With Ledger Entry");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Currency With Ledger Entry");
    end;

    [Normal]
    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        NoSeries: Codeunit "No. Series";
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(CurrencyCode));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Create multiple Purchase Lines. Make sure that No. of Lines always greater than 2 to better Testability.
        for Counter := 1 to 1 + LibraryRandom.RandInt(8) do begin
            // Required Random Value for Quantity and "Direct Unit Cost" field value is not important.
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
              LibraryRandom.RandInt(100));

            if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo" then
                PurchaseLine.Validate("Qty. to Receive", 0);  // Value not required for Purchase Credit Memo.
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
            PurchaseLine.Modify(true);
        end;
        exit(NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series"));
    end;

    [Normal]
    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(CurrencyCode));

        // Create multiple Sales Lines. Make sure that No. of Lines always greater than 2 to better Testability.
        for Counter := 1 to 1 + LibraryRandom.RandInt(8) do begin
            // Required Random Value for Quantity and "Unit Price" field value is not important.
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
            if SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo" then
                SalesLine.Validate("Qty. to Ship", 0); // Value not required for Sales Credit Memo.
            SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; LineAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Currency: Record Currency;
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(CurrencyCode, VendorLedgerEntry."Currency Code", StrSubstNo(CurrencyCodeError, CurrencyCode));

        VendorLedgerEntry.CalcFields("Amount (LCY)");
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        Assert.AreNearlyEqual(LibraryERM.ConvertCurrency(LineAmount, Currency.Code, '', WorkDate()), VendorLedgerEntry."Amount (LCY)",
          Currency."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, VendorLedgerEntry.FieldCaption("Amount (LCY)"),
            VendorLedgerEntry."Amount (LCY)", VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; LineAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(CurrencyCode, CustLedgerEntry."Currency Code", StrSubstNo(CurrencyCodeError, CurrencyCode));

        CustLedgerEntry.CalcFields("Amount (LCY)");
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
        Assert.AreNearlyEqual(LibraryERM.ConvertCurrency(LineAmount, Currency.Code, '', WorkDate()), CustLedgerEntry."Amount (LCY)",
          Currency."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, CustLedgerEntry.FieldCaption("Amount (LCY)"),
            CustLedgerEntry."Amount (LCY)", CustLedgerEntry.TableCaption()));
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

