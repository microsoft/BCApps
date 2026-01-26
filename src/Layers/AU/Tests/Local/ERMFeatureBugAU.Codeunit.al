codeunit 144004 "ERM Feature Bug AU"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeEqualMsg: Label 'Amount must be Equal.';
        LibraryERMUnapply: Codeunit "Library - ERM Unapply";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        AmountNotMatchedErr: Label 'Amount not matched.';

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithAdditionalReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        OldAdditionalReportingCurrency: Code[10];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [ACY]
        // [SCENARIO] GL Entry after posting Purchase Order with Additional Currency.

        // Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup, false, true, false);  // False for Enable GST, Round Amount for WHT Calc and True for Enable WHT.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrencyOnGLSetup(CurrencyCode);
        CreateWHTPostingSetup(WHTPostingSetup);
        CreatePurchaseOrder(PurchaseLine, CurrencyCode);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Amount := LibraryERM.ConvertCurrency(PurchaseLine.Amount, PurchaseLine."Currency Code", '', WorkDate());  // Using blank for To Currency Code.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VerifyGLEntry(DocumentNo, Amount);

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup, GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Enable WHT",
          GeneralLedgerSetup."Round Amount for WHT Calc");
        UpdateAdditionalReportingCurrencyOnGLSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTAmountOnCheckPreviewWithAdditionalCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CheckPreview: TestPage "Check Preview";
        CurrencyCode: Code[10];
        OldAdditionalReportingCurrency: Code[10];
    begin
        // [FEATURE] [WHT] [ACY]
        // [SCENARIO] WHT Amount on Check Preview with Additional Currency.

        // Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup, false, true, false);  // False for Enable GST, Round Amount for WHT Calc and True for Enable WHT.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrencyOnGLSetup(CurrencyCode);
        CreateGenJnlLineAfterPostPurchaseOrder(GenJournalLine, CurrencyCode);

        // Exercise.
        CheckPreview.OpenView();

        // Verify.
        CheckPreview.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        CheckPreview.WHTAmount.AssertEquals(GenJournalLine."WHT Absorb Base");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup, GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Enable WHT",
          GeneralLedgerSetup."Round Amount for WHT Calc");
        UpdateAdditionalReportingCurrencyOnGLSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAmountWithAdditionalReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        OldAdditionalReportingCurrency: Code[10];
    begin
        // [FEATURE] [WHT] [ACY]
        // [SCENARIO] GL Entry after posting General Journal with Additional Currency.

        // Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup, false, true, false);  // False for Enable GST, Round Amount for WHT Calc and True for Enable WHT.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        OldAdditionalReportingCurrency := UpdateAdditionalReportingCurrencyOnGLSetup(CurrencyCode);
        CreateGenJnlLineAfterPostPurchaseOrder(GenJournalLine, CurrencyCode);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        VerifyGLEntry(GenJournalLine."Document No.", -GenJournalLine."Amount (LCY)");

        // Tear Down.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup, GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Enable WHT",
          GeneralLedgerSetup."Round Amount for WHT Calc");
        UpdateAdditionalReportingCurrencyOnGLSetup(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyVendorPaymentWithWHT()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        WHTPostingSetup: Record "WHT Posting Setup";
        AmountToApply: Decimal;
        PurchInvoiceNo: Code[20];
    begin
        // [FEATURE] [WHT] [Unapply]
        // [SCENARIO 169498] Successfull unapply of Vendor Payment applied to Purchase Invoice

        // [GIVEN] WHT Posting Setup has been created
        LibraryAPACLocalization.CreateWHTPostingSetupWithPayableGLAccounts(WHTPostingSetup);

        // [GIVEN] Purchase Invoice with line containing WHT Posting Groups created.
        CreatePurchInvoiceWithWHTLine(WHTPostingSetup, PurchaseHeader, Vendor, AmountToApply);

        // [GIVEN] Purchase Invoice has been posted.
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Payment Journal Line added and set applied to Posted Purchase Invoice.
        CreatePaymentJournalLineAppliedToInvoice(GenJournalLine, WHTPostingSetup, PurchInvoiceNo, AmountToApply, Vendor."No.");

        // [GIVEN] Payment Journal Line Posted.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [WHEN] Unapply Payment Vendor Ledger Entry.
        LibraryERMUnapply.UnapplyVendorLedgerEntry(VendorLedgerEntry);

        // [THEN] Payment Entry is unapplied from Purchase Invoice.
        VendorLedgerEntry.Find();
        VendorLedgerEntry.TestField(Open, true);
    end;

    [Test]
    [HandlerFunctions('CalcandPostVATSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcandPostVATSettlementTotalVATAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 304509] Vat Amount is equal to VAT Amount of posted Sales Lines in Report "Calc. and Post VAT Settlement".

        // [GIVEN] VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(10));

        // [GIVEN] Posted Sales Order and it's Sales Line using VAT Posting Setup.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Report "Calc. and Post VAT Settlement" is run.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        LibraryVariableStorage.Enqueue(VATPostingSetup."VAT Bus. Posting Group");
        LibraryVariableStorage.Enqueue(VATPostingSetup."VAT Prod. Posting Group");
        Commit();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true);

        // [THEN] Resulting dataset has VATAmount equal to Sales Line VAT Amount.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmount', -(SalesLine."Amount Including VAT" - SalesLine.Amount));
    end;

    [Test]
    [HandlerFunctions('CalcandPostVATSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcandPostVATSettlementSubTotal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 313225] Report "Calc. and Post VAT Settlement" shows totals for zero VAT Amount Entries.

        // [GIVEN] VAT Posting Setup with zero VAT Rate.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Posted Sales Order and it's Sales Line using VAT Posting Setup.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Report "Calc. and Post VAT Settlement" is run.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        LibraryVariableStorage.Enqueue(VATPostingSetup."VAT Bus. Posting Group");
        LibraryVariableStorage.Enqueue(VATPostingSetup."VAT Prod. Posting Group");
        Commit();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true);

        // [THEN] Resulting dataset has GenJnlLineVATBaseAmount equal to Sales Line Amount and GenJnlLineVATAmount equal to "0".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GenJnlLineVATBaseAmount', SalesLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('GenJnlLineVATAmount', 0);
    end;

    local procedure CreateGenJnlLineAfterPostPurchaseOrder(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        CreateWHTPostingSetup(WHTPostingSetup);
        CreatePurchaseOrder(PurchaseLine, CurrencyCode);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.
        CreateGeneralJnlLine(GenJournalLine, WHTPostingSetup, PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATAmountAfterPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [SCENARIO 456460] Total VAT rounding issue in sales invoice and sales order.
        // [GIVEN] VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 7);

        // [GIVEN] Create Sales Invoice with new customer and set Price Including VAT true
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);

        // [GIVEN] Create first sales line with new GL Account which have VAT posting setup of 7%
        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), 3000);
        SalesLine[1].Validate("Unit Price", 1.1);
        SalesLine[1].Modify(true);

        // [GIVEN] Create second sales line with new posting GL and VAT psoting setup will be same
        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), -1);
        SalesLine[2].Validate("Unit Price", 1650);
        SalesLine[2].Modify(true);

        // [THEN] Post the document
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [VERIFY]  Verify first Sales Line VAT Base Amount and Amount Including VAT on posted invoice.
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("No.", SalesLine[1]."No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(SalesLine[1]."VAT Base Amount", SalesInvoiceLine."VAT Base Amount", AmountNotMatchedErr);
        Assert.AreEqual(SalesLine[1]."Amount Including VAT", SalesInvoiceLine."Amount Including VAT", AmountNotMatchedErr);

        // [VERIFY]  Verify second Sales Line VAT Base Amount and Amount Including VAT on posted invoice.
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("No.", SalesLine[2]."No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(SalesLine[2]."VAT Base Amount", SalesInvoiceLine."VAT Base Amount", AmountNotMatchedErr);
        Assert.AreEqual(SalesLine[2]."Amount Including VAT", SalesInvoiceLine."Amount Including VAT", AmountNotMatchedErr);
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; WHTPostingSetup: Record "WHT Posting Setup"; PurchaseLine: Record "Purchase Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          PurchaseLine."Buy-from Vendor No.", PurchaseLine.Amount);
        GenJournalLine.Validate("Currency Code", PurchaseLine."Currency Code");
        GenJournalLine.Validate("WHT Business Posting Group", WHTPostingSetup."WHT Business Posting Group");
        GenJournalLine.Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount(PurchaseLine."Currency Code"));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Random for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup")
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
    begin
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        CreateWHTPostingSetupWithRealizedWHTType(
          WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code, WHTPostingSetup."Realized WHT Type"::Invoice);
    end;

    local procedure CreateWHTPostingSetupWithRealizedWHTType(var WHTPostingSetup: Record "WHT Posting Setup"; WHTBusinessPostingGroup: Code[20]; WHTProductPostingGroup: Code[20]; RealizedWHTType: Option)
    var
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup, WHTProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandDec(10, 2));
        WHTPostingSetup.Validate("Realized WHT Type", RealizedWHTType);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Payable WHT Account Code", WHTPostingSetup."Prepaid WHT Account Code");
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", LibraryRandom.RandDec(10, 2));
        WHTPostingSetup.Validate("Bal. Payable Account No.", BankAccount."No.");
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreatePurchInvoiceWithWHTLine(var WHTPostingSetup: Record "WHT Posting Setup"; var PurchaseHeader: Record "Purchase Header"; var Vendor: Record Vendor; var AmountToApply: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreateVendorForWHT(Vendor);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDec(10, 2));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Validate("WHT Business Posting Group", WHTPostingSetup."WHT Business Posting Group");
        PurchaseLine.Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
        PurchaseLine.Modify(true);

        PurchaseHeader.CalcFields("Amount Including VAT");
        AmountToApply := PurchaseHeader."Amount Including VAT";
    end;

    local procedure CreateVendorForWHT(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.ABN := '';
        Vendor.Modify();
    end;

    local procedure CreatePaymentJournalLineAppliedToInvoice(var GenJournalLine: Record "Gen. Journal Line"; WHTPostingSetup: Record "WHT Posting Setup"; PurchInvoiceNo: Code[20]; AmountToApply: Decimal; VendorNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, AmountToApply);

        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", WHTPostingSetup."Bal. Payable Account No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PurchInvoiceNo);
        GenJournalLine.Validate("WHT Business Posting Group", WHTPostingSetup."WHT Business Posting Group");
        GenJournalLine.Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(var TempGeneralLedgerSetup: Record "General Ledger Setup" temporary; EnableGSTAustralia: Boolean; EnableWHT: Boolean; RoundAmountForWHTCalc: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        TempGeneralLedgerSetup := GeneralLedgerSetup;
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGSTAustralia);
        GeneralLedgerSetup.Validate("Enable WHT", EnableWHT);
        GeneralLedgerSetup.Validate("Round Amount for WHT Calc", RoundAmountForWHTCalc);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateAdditionalReportingCurrencyOnGLSetup(AdditionalReportingCurrency: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;  // To avoid calling report Adjust Add. Reporting Currency .
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcandPostVATSettlementRequestPageHandler(var CalcandPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcandPostVATSettlement.StartingDate.SetValue(WorkDate());
        CalcandPostVATSettlement.EndDateReq.SetValue(WorkDate());
        CalcandPostVATSettlement.PostingDt.SetValue(WorkDate());
        CalcandPostVATSettlement.VATDt.SetValue(WorkDate());
        CalcandPostVATSettlement.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CalcandPostVATSettlement.SettlementAcc.SetValue(LibraryVariableStorage.DequeueText());
        CalcandPostVATSettlement."VAT Posting Setup".SetFilter("VAT Bus. Posting Group", LibraryVariableStorage.DequeueText());
        CalcandPostVATSettlement."VAT Posting Setup".SetFilter("VAT Prod. Posting Group", LibraryVariableStorage.DequeueText());
        CalcandPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

