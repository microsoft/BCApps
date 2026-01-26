codeunit 141082 "ERM Payment - Prepayment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST] [Prepayment]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedErr: Label 'Expected value is different from Actual value.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepaymentOrderWithDifferentPrepaymentPct()
    begin
        // [SCENARIO] Program allow to posting the Sales order and creates correct prepayment invoice amount after posting the prepayment invoice with different prepayment %.
        Initialize();
        PostSalesPrepaymentOrder('');  // Blank Currency Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepaymentOrderInFCYWithDifferentPrepaymentPct()
    begin
        // [SCENARIO] Program does not create any Realized FX Gains/Loss account on G\L Entry after posting the Sales order with Prepayment & foreign currency.
        Initialize();
        PostSalesPrepaymentOrder(CreateCurrencyWithExchangeRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepaymentOrderWithHundredPrepaymentPct()
    begin
        // [SCENARIO] G/L Entries while posting of Sales Order as Ship and then Invoice after Posting the Prepayment invoice with full Prepayment.
        Initialize();
        PostSalesPrepaymentOrderWithFullPrepayment(false);  // Using False for Prices Including VAT.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesPrepaymentOrderWithPricesIncludingVAT()
    begin
        // [SCENARIO] the correct G/L entries are created in case of Prepayment Invoice where prices Including VAT True & full Prepayment.
        Initialize();
        PostSalesPrepaymentOrderWithFullPrepayment(true);  // Using True for Prices Including VAT.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchPrepaymentOrderWithDifferentPrepaymentPct()
    begin
        // [SCENARIO] Program allow posting the purchase order and creates correct prepayment invoice amount after posting the prepayment invoice with different prepayment %.
        Initialize();
        PostPurchPrepaymentOrder('');  // Blank Currency Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchPrepaymentOrderInFCYWithDifferentPrepaymentPct()
    begin
        // [SCENARIO] Program does not create any Realized FX Gains/Loss account on G\L Entry after Posting the Purchase Order with Prepayment & Foreign currency.
        Initialize();
        PostPurchPrepaymentOrder(CreateCurrencyWithExchangeRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchPrepaymentOrderWithHundredPrepaymentPct()
    begin
        // [SCENARIO] G/L Entries while posting of Purchase Order as Receive and then Invoice after Posting the Prepayment invoice with full Prepayment.
        Initialize();
        PostPurchOrderWithPrepaymentPct(true);  // Using True for Compress Statement.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchPrepaymentOrderWithoutCompressPrepayment()
    begin
        // [SCENARIO] Program allow to posting the Sales order with Partial prepayment % when Compress Prepayment field in Uncheck on the Prepayment tab of Purchase order.
        Initialize();
        PostPurchOrderWithPrepaymentPct(false);  // Using False for Compress Statement.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchPrepaymentOrderWithCreditMemoPrepaymentAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        // [SCENARIO] program does not create any Realized Loss/Gain Account after posting the Prepayment Credit memos on the Purchase order with partial prepayment & foreign currency.
        // Setup.
        Initialize();
        CreateAndPostPurchasePrepayment(PurchaseLine, '', LibraryRandom.RandDec(10, 2), true);  // Using Random for Prepayment %, TRUE for Compress Statement and blank Currency Code.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);
        PurchaseLine.Validate("Prepayment %");
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise, Verify & Teardown.
        PostPurchaseDocumentAndVerifyGLEntry(PurchaseHeader, Round(PurchaseLine."Amount Including VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesFullPrepaymentPartialReceiptFinalInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        QtyToShip: array[3] of Decimal;
        Index: Integer;
    begin
        // [SCENARIO 376381] Posted Final Shipment and Invoice after 100% prepayment and partial shipment produces Customer Ledger Entry with Amount = 0
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] Enabled Full GST on Prepayment
        // [GIVEN] Sales Header with 100% prepayment settings and 3 Sales Lines
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);
        for Index := 1 to ArrayLen(QtyToShip) do
            CreateSalesLine(SalesHeader, SalesLine);

        // [GIVEN] Posted 100% Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Ship only 1st line.
        InitArray(QtyToShip, 1, 0, 0);
        UpdateSalesLinesQtyToShip(SalesLine, QtyToShip);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Ship and Invoice remaining Sales Lines
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted "Customer Ledger Entry".Amount = 0
        VerifyCustomerLedgerEntry(DocumentNo, SalesHeader."Sell-to Customer No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchFullPrepaymentPartialReceiptFinalInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        QtyToReceive: array[3] of Decimal;
        Index: Integer;
    begin
        // [SCENARIO 376381] Posted Final Receipt and Invoice after 100% prepayment and partial receipt produces Vendor Ledger Entry with Amount = 0
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] Enabled Full GST on Prepayment
        // [GIVEN] Purchase Header with 100% prepayment settings and 3 Purchase Lines
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);
        for Index := 1 to ArrayLen(QtyToReceive) do
            CreatePurchaseLine(PurchaseHeader, PurchaseLine);

        // [GIVEN] Posted 100% Prepayment Invoice
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Receipt only 1st line.
        InitArray(QtyToReceive, 1, 0, 0);
        UpdatePurchaseLinesQtyToReceive(PurchaseLine, QtyToReceive);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Receipt and Invoice remaining Purchase Lines
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted "Vendor Ledger Entry".Amount = 0
        VerifyVendorLedgerEntry(DocumentNo, PurchaseHeader."Buy-from Vendor No.", 0);
    end;

    local procedure Initialize()
    begin
        UpdateFullGSTOnPrepaymentGeneralLedgerSetup(true);  // Using True For Full GST on Prepayment in all tests
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    local procedure CreateAndPostPurchasePrepayment(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; PrepaymentPct: Decimal; CompressPrepayment: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Compress Prepayment", CompressPrepayment);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreateAndPostSalesPrepayment(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; CustomerNo: Code[20]; PricesIncludingVAT: Boolean; PrepaymentPct: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdatePrepmtAccInGeneralPostingSetup(
          SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdatePrepmtAccInGeneralPostingSetup(
          PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure InitArray(var ValueArray: array[3] of Decimal; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal)
    begin
        ValueArray[1] := Amount1;
        ValueArray[2] := Amount2;
        ValueArray[3] := Amount3;
    end;

    local procedure PostSalesPrepaymentOrder(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Amount: Decimal;
    begin
        // Setup.
        CreateAndPostSalesPrepayment(SalesLine, CurrencyCode, CreateCustomer(), false, LibraryRandom.RandDec(10, 2));  // Using Random Value and FALSE for Price Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Prepayment %", 100);  // 100 is required prepayment in test case.
        SalesHeader.Modify(true);
        Amount :=
          Round(
            LibraryERM.ConvertCurrency(SalesLine."Amount Including VAT" * SalesHeader."Prepayment %" / 100,
              SalesHeader."Currency Code", '', SalesHeader."Posting Date"));  // Blank is using for to Currency Code.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise, Verify & Teardown.
        PostSalesDocumentAndVerifyGLEntry(SalesHeader, Amount);
    end;

    local procedure PostSalesPrepaymentOrderWithFullPrepayment(PricesIncludingVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        CreateAndPostSalesPrepayment(SalesLine, '', CreateCustomer(), PricesIncludingVAT, 100);  // 100 is required prepayment in test case and blank Currency Code.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise, Verify & Teardown.
        PostSalesDocumentAndVerifyGLEntry(SalesHeader, Round(SalesLine."Amount Including VAT"));
    end;

    local procedure PostPurchPrepaymentOrder(CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
    begin
        // Setup.
        CreateAndPostPurchasePrepayment(PurchaseLine, CurrencyCode, LibraryRandom.RandDec(10, 2), true);  // Using Random for Prepayment % and TRUE for Compress Statement.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        PurchaseLine.Validate("Prepayment %", 100);  // 100 is required prepayment in test case.
        PurchaseLine.Modify(true);
        Amount :=
          Round(
            LibraryERM.ConvertCurrency(PurchaseLine."Amount Including VAT" * PurchaseLine."Prepayment %" / 100,
              PurchaseHeader."Currency Code", '', PurchaseHeader."Posting Date"));  // Blank is using for to Currency Code.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise, Verify & Teardown.
        PostPurchaseDocumentAndVerifyGLEntry(PurchaseHeader, Amount);
    end;

    local procedure PostPurchOrderWithPrepaymentPct(CompressStatement: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup.
        CreateAndPostPurchasePrepayment(PurchaseLine, '', LibraryRandom.RandDec(10, 2), CompressStatement);  // Using Random for Prepayment % and blank Currency Code.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise, Verify & Teardown.
        PostPurchaseDocumentAndVerifyGLEntry(PurchaseHeader, Round(PurchaseLine."Amount Including VAT"));
    end;

    local procedure PostPurchaseDocumentAndVerifyGLEntry(PurchaseHeader: Record "Purchase Header"; Amount: Decimal)
    var
        DocumentNo: Code[20];
    begin
        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyGLEntry(DocumentNo, Amount);
    end;

    local procedure PostSalesDocumentAndVerifyGLEntry(SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        DocumentNo: Code[20];
    begin
        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyGLEntry(DocumentNo, Amount);
    end;

    local procedure UpdateFullGSTOnPrepaymentGeneralLedgerSetup(FullGSTOnPrepayment: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Full GST on Prepayment", FullGSTOnPrepayment);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePrepmtAccInGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Sales Prepayments Account", CreateGLAccount());
        GeneralPostingSetup.Validate("Purch. Prepayments Account", CreateGLAccount());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateSalesLinesQtyToShip(var SalesLine: Record "Sales Line"; QtyToShip: array[3] of Decimal)
    var
        Index: Integer;
    begin
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.FindSet();
        for Index := 1 to ArrayLen(QtyToShip) do begin
            SalesLine.Validate("Qty. to Ship", QtyToShip[Index]);
            SalesLine.Modify(true);
            SalesLine.Next();
        end;
    end;

    local procedure UpdatePurchaseLinesQtyToReceive(var PurchaseLine: Record "Purchase Line"; QtyToReceive: array[3] of Decimal)
    var
        Index: Integer;
    begin
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.FindSet();
        for Index := 1 to ArrayLen(QtyToReceive) do begin
            PurchaseLine.Validate("Qty. to Receive", QtyToReceive[Index]);
            PurchaseLine.Modify(true);
            PurchaseLine.Next();
        end;
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums("Credit Amount");
        Assert.AreNearlyEqual(
          ExpectedAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), UnexpectedErr);
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; CustomerNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.TestField(Amount, ExpectedAmount);
    end;
}

