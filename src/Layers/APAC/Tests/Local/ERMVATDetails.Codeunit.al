codeunit 141038 "ERM VAT - Details"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
        IsInitialized := true;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeEqual: Label 'Amount must be equal.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithNegativeQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify GL and VAT Entry after posting sales credit memo with negative quantity.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesLine, SalesLine."Document Type"::"Credit Memo");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine2, SalesHeader, -LibraryRandom.RandDecInRange(1, 10, 2)); // Random for Quantity.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true); // True for ship and invoice.

        // Verify.
        VerifyGLEntry(
          DocumentNo, SalesLine."Amount Including VAT",
          SalesLine2."Amount Including VAT" - (SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT"));
        VerifyVATEntry(DocumentNo, '>%1', SalesLine."Amount Including VAT" - SalesLine.Amount);
        VerifyVATEntry(DocumentNo, '<%1', SalesLine2."Amount Including VAT" - SalesLine2.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithNegativeQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Verify GL and VAT Entry after posting sales invoice with negative quantity.

        // Setup.
        Initialize();
        CreateSalesOrder(SalesLine, SalesLine."Document Type"::Invoice);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine2, SalesHeader, -LibraryRandom.RandDecInRange(1, 10, 2)); // Random for Quantity.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true); // True for ship and invoice.

        // Verify.
        VerifyGLEntry(
          DocumentNo, SalesLine."Amount Including VAT",
          SalesLine2."Amount Including VAT" - (SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT"));
        VerifyVATEntry(DocumentNo, '>%1', SalesLine2.Amount - SalesLine2."Amount Including VAT");
        VerifyVATEntry(DocumentNo, '<%1', SalesLine.Amount - SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWithNegativeQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify GL and VAT Entry after posting purchase credit memo with negative quantity.

        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, -LibraryRandom.RandDecInRange(1, 10, 2)); // Random for Quantity, less value from previous line.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true); // True for receive and invoice.

        // Verify.
        VerifyGLEntry(
          DocumentNo, PurchaseLine."Amount Including VAT",
          PurchaseLine2."Amount Including VAT" - (PurchaseLine."Amount Including VAT" + PurchaseLine2."Amount Including VAT"));
        VerifyVATEntry(DocumentNo, '>%1', PurchaseLine2.Amount - PurchaseLine2."Amount Including VAT");
        VerifyVATEntry(DocumentNo, '<%1', PurchaseLine.Amount - PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithNegativeQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Verify GL and VAT Entry after posting purchase invoice with negative quantity.

        // Setup.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, PurchaseLine."Document Type"::Invoice);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, -LibraryRandom.RandDecInRange(1, 10, 2)); // Random for Quantity, less value from previous line.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true); // True for receive and invoice.

        // Verify.
        VerifyGLEntry(
          DocumentNo, PurchaseLine."Amount Including VAT",
          PurchaseLine2."Amount Including VAT" - (PurchaseLine."Amount Including VAT" + PurchaseLine2."Amount Including VAT"));
        VerifyVATEntry(DocumentNo, '<%1', PurchaseLine2."Amount Including VAT" - PurchaseLine2.Amount);
        VerifyVATEntry(DocumentNo, '>%1', PurchaseLine."Amount Including VAT" - PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAdditionalCurrency()
    var
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales][ACY]
        // [SCENARIO 374865] Post Sales Invoice with Additional Reporting Currency
        Initialize();

        // [GIVEN] Currency with "Exchange Rate Amount" = 7
        CreateCurrencyWithExchRateAmount(CurrencyCode);
        UpdateGenLedgSetupAddReportingCurrency(CurrencyCode);
        // [GIVEN] VAT Posting Setup with "VAT %" = 20%
        // [GIVEN] Sales invoice with 2 lines
        // [GIVEN] Amount of first line = 10
        // [GIVEN] Amount of second line = 20

        // [WHEN] Post Sales Invoice
        DocumentNo := PostSalesInvWithTwoLines(CustomerNo);

        // [THEN] "VAT Entry"."Additional Currency Base" = (10 + 20) * 7 = 210
        // [THEN] "VAT Entry"."Additional Currency Amount" = 210 * 20% = 42
        VerifyPostedSalesVATEntries(DocumentNo, CurrencyCode, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithAdditionalCurrency()
    var
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase][ACY]
        // [SCENARIO 374865] Post Purchase Invoice with Additional Reporting Currency
        Initialize();

        // [GIVEN] Currency with "Exchange Rate Amount" = 7
        CreateCurrencyWithExchRateAmount(CurrencyCode);
        UpdateGenLedgSetupAddReportingCurrency(CurrencyCode);
        // [GIVEN] VAT Posting Setup with "VAT %" = 20%
        // [GIVEN] Purchase invoice with 2 lines
        // [GIVEN] Amount of first line = 10
        // [GIVEN] Amount of second line = 20

        // [WHEN] Post Purchase Invoice
        DocumentNo := PostPurchInvWithTwoLines(VendorNo);

        // [THEN] "VAT Entry"."Additional Currency Base" = (10 + 20) * 7 = 210
        // [THEN] "VAT Entry"."Additional Currency Amount" = 210 * 20% = 42
        VerifyPostedPurchVATEntries(DocumentNo, CurrencyCode, VendorNo);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryRandom.RandDecInRange(100, 200, 2)); // Random for Quantity.
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, LibraryRandom.RandDecInRange(100, 200, 2)); // Random for Quantity.
    end;

    local procedure CreateCurrencyWithExchRateAmount(var CurrencyCode: Code[10])
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        LibraryERM.CreateRandomExchangeRate(CurrencyCode);
    end;

    local procedure UpdateGenLedgSetupAddReportingCurrency(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure PostPurchInvWithTwoLines(var VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryRandom.RandInt(100));
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, LibraryRandom.RandInt(100));
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesInvWithTwoLines(var CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, LibraryRandom.RandInt(100));
        CreateSalesLine(SalesLine, SalesHeader, LibraryRandom.RandInt(100));
        CustomerNo := SalesHeader."Sell-to Customer No.";
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetPercent(Amount: Decimal; ValueProc: Decimal): Decimal
    begin
        exit(Amount / 100 * ValueProc);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; AmountIncludingVATCredit: Decimal; AmountIncludingVATDebit: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.CalcSums("Credit Amount", "Debit Amount");
        Assert.AreNearlyEqual(AmountIncludingVATCredit, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
        Assert.AreNearlyEqual(AmountIncludingVATDebit, -GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; AmountFilter: Text; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetFilter(Amount, AmountFilter, 0);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqual);
    end;

    local procedure VerifyVATEntryACY(DocumentNo: Code[20]; LineBase: Decimal; VATAmountACY: Decimal; VATBaseACY: Decimal; VendCustNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Bill-to/Pay-to No.", VendCustNo);
        VATEntry.SetRange(Base, LineBase);
        VATEntry.FindFirst();
        VATEntry.TestField("Additional-Currency Amount", VATAmountACY);
        VATEntry.TestField("Additional-Currency Base", VATBaseACY);
    end;

    local procedure VerifyPostedSalesVATEntries(DocumentNo: Code[20]; CurrencyCode: Code[10]; CustomerNo: Code[20])
    var
        SalesInvLine: Record "Sales Invoice Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrAmountRoundingPrecision: Decimal;
        CurrencyFactor: Decimal;
    begin
        CurrAmountRoundingPrecision := LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode);
        CurrencyFactor := CurrencyExchangeRate.GetCurrentCurrencyFactor(CurrencyCode);
        SalesInvLine.SetRange("Document No.", DocumentNo);
        SalesInvLine.FindSet();
        repeat
            VerifyVATEntryACY(
              DocumentNo, -SalesInvLine.Amount,
              -Round(GetPercent(SalesInvLine.Amount, SalesInvLine."VAT %") * CurrencyFactor, CurrAmountRoundingPrecision),
              -Round(SalesInvLine.Amount * CurrencyFactor, CurrAmountRoundingPrecision), CustomerNo);
        until SalesInvLine.Next() = 0;
    end;

    local procedure VerifyPostedPurchVATEntries(DocumentNo: Code[20]; CurrencyCode: Code[10]; VendorNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrAmountRoundingPrecision: Decimal;
        CurrencyFactor: Decimal;
    begin
        CurrAmountRoundingPrecision := LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode);
        CurrencyFactor := CurrencyExchangeRate.GetCurrentCurrencyFactor(CurrencyCode);
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindSet();
        repeat
            VerifyVATEntryACY(
              DocumentNo, PurchInvLine.Amount,
              Round(GetPercent(PurchInvLine.Amount, PurchInvLine."VAT %") * CurrencyFactor, CurrAmountRoundingPrecision),
              Round(PurchInvLine.Amount * CurrencyFactor, CurrAmountRoundingPrecision), VendorNo);
        until PurchInvLine.Next() = 0;
    end;
}

