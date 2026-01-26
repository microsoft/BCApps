codeunit 144066 "Test CH PAYDISC Sales Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCH: Codeunit "Library - CH";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        IsInitialized: Boolean;
        PmtApplnErr: Label 'You cannot post and apply general journal line %1, %2, %3 because the corresponding balance contains VAT.', Comment = '%1 - Template name, %2 - Batch name, %3 - Line no.';
        VATEntryCountErr: Label 'New VAT entry not created';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH PAYDISC Sales Docs");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH PAYDISC Sales Docs");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", true);
        GeneralLedgerSetup.Modify(true);

        SourceCodeSetup.Get();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH PAYDISC Sales Docs");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPmtToSalesInvoiceDuringPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PmtGenJournalLine: Record "Gen. Journal Line";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Customer, GLAccount);
        ApplyBeforePosting(CustLedgerEntry, PmtGenJournalLine, Customer, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(CustLedgerEntry);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(PmtGenJournalLine);
        VerifyApplicationWithVATBalancingError(PmtGenJournalLine);
        if true then
            exit; // We reject possibility to apply payment with VAT and Discount on a balance account until proper fix (split transaction)

        // Verify.
        CustLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, CustLedgerEntry, PmtDiscountFCY, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmtToSalesInvoiceDuringPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PmtGenJournalLine: Record "Gen. Journal Line";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Customer, GLAccount);
        ApplyBeforePosting(CustLedgerEntry, PmtGenJournalLine, Customer, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(CustLedgerEntry);

        asserterror LibraryERM.PostGeneralJnlLine(PmtGenJournalLine);
        VerifyApplicationWithVATBalancingError(PmtGenJournalLine);
        if true then
            exit; // We reject possibility to apply payment with VAT and Discount on a balance account until proper fix (split transaction)

        // Exercise.
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindLast();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Verify.
        CustLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, CustLedgerEntry, PmtDiscountFCY, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPmtToSalesInvoiceAfterPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Customer, GLAccount);
        ApplyAfterPosting(CustLedgerEntry, Customer, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(CustLedgerEntry);

        // Exercise.
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // Verify.
        CustLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, CustLedgerEntry, PmtDiscountFCY, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmtToSalesInvoiceAfterPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PmtDiscountFCY: Decimal;
    begin
        Initialize();

        // Setup.
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Customer, GLAccount);
        ApplyAfterPosting(CustLedgerEntry, Customer, GLAccount);
        PmtDiscountFCY := GetPmtDiscount(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // Exercise. Unapply.
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Verify.
        CustLedgerEntry.SetAutoCalcFields("Original Amt. (LCY)", "Original Amount");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        VerifyVATEntry(CurrencyExchangeRate, VATPostingSetup, CustLedgerEntry, PmtDiscountFCY, 3);
    end;

    [Test]
    [HandlerFunctions('ChangePmtToleranceReqPageHandler,ConfirmHandler,PmtToleranceWarningModalPageHandler')]
    [Scope('OnPrem')]
    procedure PmtDiscountToleranceWarning()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        InvGenJournalLine: Record "Gen. Journal Line";
        PmtGenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentToleranceManagement: Codeunit "Payment Tolerance Management";
        MaxToleranceAmt: Decimal;
    begin
        Initialize();

        // Setup.
        GenJournalTemplate.DeleteAll();
        GeneralLedgerSetup.Get();
        UpdateGenLedgerSetup(true, true, GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        Commit();
        MaxToleranceAmt := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(MaxToleranceAmt);
        REPORT.Run(REPORT::"Change Payment Tolerance", true, false);
        GeneralLedgerSetup.Get();
        SetupVATForFCY(VATPostingSetup, CurrencyExchangeRate, Customer, GLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine."Document Type"::Invoice, InvGenJournalLine."Account Type"::Customer, Customer."No.",
          InvGenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2));
        InvGenJournalLine.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        InvGenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(InvGenJournalLine);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindLast();
        CustLedgerEntry.Validate("Pmt. Disc. Tolerance Date", WorkDate() + 1);
        CustLedgerEntry.Validate("Max. Payment Tolerance", MaxToleranceAmt);
        CustLedgerEntry.Modify(true);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(PmtGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PmtGenJournalLine."Document Type"::Payment, PmtGenJournalLine."Account Type"::Customer, Customer."No.",
          PmtGenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.",
          -CustLedgerEntry."Remaining Amount" + CustLedgerEntry."Remaining Pmt. Disc. Possible" - MaxToleranceAmt);
        PmtGenJournalLine.Validate("Applies-to Doc. Type", CustLedgerEntry."Document Type");
        PmtGenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        PmtGenJournalLine.Modify(true);

        // Exercise. Force tolerance warning.
        PaymentToleranceManagement.SetBatchMode(false);
        PaymentToleranceManagement.PmtTolGenJnl(PmtGenJournalLine);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(PmtGenJournalLine);
        VerifyApplicationWithVATBalancingError(PmtGenJournalLine);

        // Verify: No warning.

        // Rollback.
        UpdateGenLedgerSetup(GeneralLedgerSetup."Pmt. Disc. Tolerance Warning", GeneralLedgerSetup."Payment Tolerance Warning",
          GeneralLedgerSetup."Pmt. Disc. Tolerance Posting");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExchangeRateAdjustmentCheckVATEntryWhileAdjustVATTrue()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        BeforeVATCount: Integer;
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO 573894] Check new VAT entry created from Exchange Rate adjustment when only "Adjust VAT" True on report.
        Initialize();

        // [GIVEN] Set New WorkDate.
        WorkDate(DMY2Date(1, 1, 2025));

        // [GIVEN] Create Currency With Exchange Rate using new workdate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        ModifyCurrencyExchangeRate(CurrencyCode);

        // [GIVEN] Create VAT Posting Setup with "VAT Calculation Type" = "Normal VAT".
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', '');

        // [GIVEN] Create Vendor With VAT Bus Posting Group.
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create GL Account.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        ModifyGLAccount(GLAccount, GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Create And Post Purchase Invoice with line GL Account.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify();
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate(Amount, 10000);
        PurchaseLine.Modify();
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Count VAT Entry Before Running Exch. Rate Adjustment Report.
        VATEntry.SetRange("Document No.", InvoiceNo);
        if VATEntry.Findset() then
            BeforeVATCount := VATEntry.Count;

        // [WHEN] Adjusted exchange rate Report Run with only "Adjust VAT" True on Request Page.
        RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        // [WHEN] Count VAT Entry After Running Exch. Rate Adjustment Report.
        Clear(VATEntry);
        VATEntry.SetRange("Document No.", InvoiceNo);
        if VATEntry.Findset() then;

        // [THEN] Actual Result VAT Entry Count Must Not Eqalt to BeforeVATCount, New VAT Entry Must Created after Running Exch. Rate Adjustment Report.
        Assert.AreNotEqual(BeforeVATCount, VATEntry.Count, VATEntryCountErr);
    end;

    local procedure ApplyAfterPosting(var CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer; GLAccount: Record "G/L Account")
    var
        InvGenJournalLine1: Record "Gen. Journal Line";
        InvGenJournalLine2: Record "Gen. Journal Line";
        PmtGenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Post invoices and payment.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine1."Document Type"::Invoice, InvGenJournalLine1."Account Type"::Customer, Customer."No.",
          InvGenJournalLine1."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine2."Document Type"::Invoice, InvGenJournalLine2."Account Type"::Customer, Customer."No.",
          InvGenJournalLine2."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2));
        InvGenJournalLine2.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        InvGenJournalLine2.Modify(true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(PmtGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PmtGenJournalLine."Document Type"::Payment, PmtGenJournalLine."Account Type"::Customer, Customer."No.",
          PmtGenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.",
          -InvGenJournalLine1.Amount - InvGenJournalLine2.Amount * (1 - InvGenJournalLine2."Payment Discount %" / 100));
        LibraryERM.PostGeneralJnlLine(InvGenJournalLine1);

        // Apply payment to invoices.
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure ApplyBeforePosting(var CustLedgerEntry: Record "Cust. Ledger Entry"; var PmtGenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer; GLAccount: Record "G/L Account")
    var
        InvGenJournalLine1: Record "Gen. Journal Line";
        InvGenJournalLine2: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        AmtToApply: Decimal;
    begin
        // Post invoices.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine1."Document Type"::Invoice, InvGenJournalLine1."Account Type"::Customer, Customer."No.",
          InvGenJournalLine1."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLineWithBalAcc(InvGenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          InvGenJournalLine2."Document Type"::Invoice, InvGenJournalLine2."Account Type"::Customer, Customer."No.",
          InvGenJournalLine2."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(1000, 2));
        InvGenJournalLine2.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        InvGenJournalLine2.Modify(true);
        LibraryERM.PostGeneralJnlLine(InvGenJournalLine1);

        // Create and apply payment.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(PmtGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          PmtGenJournalLine."Document Type"::Payment, PmtGenJournalLine."Account Type"::Customer, Customer."No.",
          PmtGenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", 0);
        PmtGenJournalLine.Validate("Applies-to ID", UserId);

        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindSet();
        repeat
            SetAppliesToIdOnCustLedgerEntry(CustLedgerEntry, AmtToApply);
        until CustLedgerEntry.Next() = 0;

        PmtGenJournalLine.Validate(Amount, -AmtToApply);
        PmtGenJournalLine.Modify(true);
    end;

    local procedure SetAppliesToIdOnCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var AmtToApply: Decimal)
    begin
        CustLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgerEntry.Validate("Applies-to ID", UserId);
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible");
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
        AmtToApply += CustLedgerEntry."Amount to Apply";
    end;

    local procedure GetPmtDiscount(var CustLedgerEntry: Record "Cust. Ledger Entry"): Decimal
    begin
        CustLedgerEntry.CalcSums("Original Pmt. Disc. Possible");
        exit(CustLedgerEntry."Original Pmt. Disc. Possible");
    end;

    local procedure SetupVATForFCY(var VATPostingSetup: Record "VAT Posting Setup"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; var Customer: Record Customer; var GLAccount: Record "G/L Account")
    var
        Currency: Record Currency;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', '');
        VATPostingSetup.TestField("Adjust for Payment Discount", true);

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        LibrarySales.CreateCustomer(Customer);
        Customer."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Customer.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Customer.Modify(true);

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", GeneralPostingSetup."Sales Account");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", GeneralPostingSetup."Sales Account");
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Credit Acc.", GeneralPostingSetup."Sales Account");
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Debit Acc.", GeneralPostingSetup."Sales Account");
        GeneralPostingSetup.Modify(true);

        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure VerifyVATEntry(CurrencyExchangeRate: Record "Currency Exchange Rate"; VATPostingSetup: Record "VAT Posting Setup"; CustLedgerEntry: Record "Cust. Ledger Entry"; PmtDiscountAmtFCY: Decimal; ExpEntries: Integer)
    var
        VATEntry: Record "VAT Entry";
        PrevTransactionNo: Integer;
        sign: Integer;
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", CustLedgerEntry."Customer No.");
        VATEntry.SetRange("Document Type", CustLedgerEntry."Document Type");
        VATEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        VATEntry.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
        VATEntry.SetRange("VAT %", VATPostingSetup."VAT %");
        VATEntry.SetRange("Currency Factor", CurrencyExchangeRate."Exchange Rate Amount");
        VATEntry.SetRange("Currency Code", CurrencyExchangeRate."Currency Code");
        VATEntry.SetRange("Unadjusted Exchange Rate", true);
        VATEntry.SetRange("Exchange Rate Adjustment", false);
        Assert.AreEqual(ExpEntries, VATEntry.Count, 'Unexpected VAT entries:' + VATEntry.GetFilters);

        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Source Code", SourceCodeSetup."General Journal");
        VATEntry.FindSet();
        sign := -1;
        repeat
            if VATEntry."Transaction No." <> PrevTransactionNo then
                sign *= -1;
            case VATEntry."Sales Tax Connection No." of
                1, 3:
                    begin
                        Assert.AreEqual(-CustLedgerEntry."Original Amt. (LCY)", sign * (VATEntry.Base + VATEntry.Amount), 'Wrong VAT LCY total.');
                        Assert.AreEqual(-CustLedgerEntry."Original Amount", VATEntry."Base (FCY)" + VATEntry."Amount (FCY)",
                          'Wrong VAT FCY total.');
                        Assert.AreEqual(Round(-CustLedgerEntry."Original Amt. (LCY)" / (1 + VATPostingSetup."VAT %" / 100),
                            GeneralLedgerSetup."Amount Rounding Precision"), sign * VATEntry.Base, 'Wrong VAT Base Amount LCY.');
                        Assert.AreEqual(Round(-CustLedgerEntry."Original Amount" / (1 + VATPostingSetup."VAT %" / 100),
                            GeneralLedgerSetup."Amount Rounding Precision"), VATEntry."Base (FCY)", 'Wrong VAT Base Amount FCY.');
                    end;
                2:
                    Assert.AreNearlyEqual(PmtDiscountAmtFCY, VATEntry."Base (FCY)" + VATEntry."Amount (FCY)",
                      GeneralLedgerSetup."Inv. Rounding Precision (LCY)", 'Wrong Disc VAT FCY total.');
            end;
            PrevTransactionNo := VATEntry."Transaction No.";
        until VATEntry.Next() = 0;

        VATEntry.SetRange("Source Code", SourceCodeSetup.Reversal);
        if VATEntry.FindSet() then
            repeat
                case VATEntry."Sales Tax Connection No." of
                    1, 3:
                        begin
                            Assert.AreEqual(-CustLedgerEntry."Original Amt. (LCY)", -VATEntry.Base - VATEntry.Amount, 'Wrong VAT LCY total.');
                            Assert.AreEqual(-CustLedgerEntry."Original Amount", -VATEntry."Base (FCY)" - VATEntry."Amount (FCY)",
                              'Wrong VAT FCY total.');
                            Assert.AreEqual(Round(-CustLedgerEntry."Original Amt. (LCY)" / (1 + VATPostingSetup."VAT %" / 100),
                                GeneralLedgerSetup."Amount Rounding Precision"), -VATEntry.Base, 'Wrong VAT Base Amount LCY.');
                            Assert.AreEqual(Round(-CustLedgerEntry."Original Amount" / (1 + VATPostingSetup."VAT %" / 100),
                                GeneralLedgerSetup."Amount Rounding Precision"), -VATEntry."Base (FCY)", 'Wrong VAT Base Amount FCY.');
                        end;
                    2:
                        Assert.AreNearlyEqual(PmtDiscountAmtFCY, -VATEntry."Base (FCY)" - VATEntry."Amount (FCY)",
                          GeneralLedgerSetup."Inv. Rounding Precision (LCY)", 'Wrong Disc VAT FCY total.');
                end;
            until VATEntry.Next() = 0;

        VATEntry.SetRange("Source Code", SourceCodeSetup."Sales Entry Application");
        if VATEntry.FindSet() then
            repeat
                Assert.AreNearlyEqual(PmtDiscountAmtFCY, VATEntry."Base (FCY)" + VATEntry."Amount (FCY)",
                  GeneralLedgerSetup."Inv. Rounding Precision (LCY)", 'Wrong Disc VAT FCY total.');
            until VATEntry.Next() = 0;
    end;

    [Normal]
    local procedure UpdateGenLedgerSetup(PmtDiscToleranceWarning: Boolean; PmtToleranceWarning: Boolean; PmtDiscTolerancePosting: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", PmtDiscToleranceWarning);
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", PmtToleranceWarning);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Posting", PmtDiscTolerancePosting);
        GeneralLedgerSetup.Modify();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random Unit Price between 1 and 100.
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyCurrencyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.Get(CurrencyCode, WorkDate());
        CurrencyExchangeRate."Relational Exch. Rate Amount" := 1.1;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := 1.1;
        CurrencyExchangeRate."VAT Exch. Rate Amount" := 1;
        CurrencyExchangeRate."Relational VAT Exch. Rate Amt" := 1.2;
        CurrencyExchangeRate.Modify();
    end;

    local procedure ModifyGLAccount(var GLAccount: Record "G/L Account"; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure RunExchRateAdjustmentSimple(CurrencyCode: Code[10]; EndDate: Date; PostingDate: Date)
    begin
        RunExchRateAdjustment(CurrencyCode, 0D, EndDate, 'Test', PostingDate, LibraryUtility.GenerateGUID(), false);
    end;

    local procedure RunExchRateAdjustment(CurrencyCode: Code[10]; StartDate: Date; EndDate: Date; PostingDescription: Text[50]; PostingDate: Date; PostingDocNo: Code[20]; AdjGLAcc: Boolean)
    var
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyCode);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.InitializeRequest2(StartDate, EndDate, PostingDescription, PostingDate, PostingDocNo, false, AdjGLAcc);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.SetHideUI(true);
        ExchRateAdjustment.SetAdjustVATEntries(true);
        ExchRateAdjustment.Run();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangePmtToleranceReqPageHandler(var ChangePaymentTolerance: TestRequestPage "Change Payment Tolerance")
    var
        MaxToleranceAmt: Variant;
    begin
        LibraryVariableStorage.Dequeue(MaxToleranceAmt);
        ChangePaymentTolerance.AllCurrencies.SetValue(true); // All currencies.
        ChangePaymentTolerance.PaymentTolerancePct.SetValue(LibraryRandom.RandInt(10));
        ChangePaymentTolerance."Max. Pmt. Tolerance Amount".SetValue(MaxToleranceAmt);
        ChangePaymentTolerance.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtToleranceWarningModalPageHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        PaymentToleranceWarning.Posting.SetValue(PaymentToleranceWarning.Posting.GetOption(1));
        PaymentToleranceWarning.Yes().Invoke();
    end;

    local procedure VerifyApplicationWithVATBalancingError(GenJournalLine: Record "Gen. Journal Line")
    begin
        Assert.ExpectedError(
            StrSubstNo(
                PmtApplnErr, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;
}

