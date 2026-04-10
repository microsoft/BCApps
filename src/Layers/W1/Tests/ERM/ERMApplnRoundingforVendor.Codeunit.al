codeunit 134903 "ERM Appln Rounding for Vendor"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Application Rounding] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure HigherPaymentWithApplRundng()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        DocumentNo: Code[20];
        ApplnRounding: Decimal;
        CurrencyCode: Code[10];
        ExchRateAmount: Decimal;
        ExchRateAmount2: Decimal;
    begin
        // Check that Application Rounding entry Created in Detailed Ledger Entry after Post Invoice and Payment from General Journal
        // Lines and Modify Exchange Rate and Modify General Ledger Setup for Appln. Rounding Precision.

        // Create and Post General Line for Invoice and Payment with currency, Modify Exchange Rate and Apply invoice and Modify
        // General Ledger Setup for Random Appln. Roudning Precision.
        Initialize();
        GeneralLedgerSetup.Get();
        ApplnRounding := GeneralLedgerSetup."Appln. Rounding Precision";
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandInt(100);
        ExchRateAmount := LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate());
        ExchRateAmount2 := ExchRateAmount + LibraryUtility.GenerateRandomFraction();
        ApplyPaymentWithHigherValue(DocumentNo, CurrencyCode, -Amount, ExchRateAmount2, LibraryRandom.RandInt(2));
        Amount := ExchRateAmount2 - ExchRateAmount;

        // Verify: Verify that Application Rounding Entry created on Detailed Ledger Entry.
        VerifyDetailedLedgerEntry(DocumentNo, -Amount, CurrencyCode);

        // TearDown: Set Zero on General Ledger Setup for Application Rounding Precision.
        ModifyGenLedgerSetup(ApplnRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HigherPaymentWithoutApplRundng()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApplnRounding: Decimal;
        Amount: Decimal;
        DocumentNo: Code[20];
        ExchRateAmount: Decimal;
    begin
        // Check that Application Rounding entry not Created in Detailed Ledger Entry after Post Invoice and Payment from General Journal
        // Lines and Modify Exchange Rate and Modify General Ledger Setup for Appln. Rounding Precision.

        // Create and Post General Line for Invoice and Payment with currency, Modify Exchange Rate and Apply invoice and Modify
        // General Ledger Setup for Random Appln. Roudning Precision
        Initialize();
        GeneralLedgerSetup.Get();
        ApplnRounding := GeneralLedgerSetup."Appln. Rounding Precision";
        Amount := LibraryRandom.RandInt(100);
        ExchRateAmount := Amount - LibraryUtility.GenerateRandomFraction();
        ApplyPaymentWithHigherValue(DocumentNo, '', -Amount, ExchRateAmount, LibraryRandom.RandInt(2));

        // Verify: Verify that Application Rounding Entry not created on Detailed Ledger Entry.
        VerifyDetldLdgrWithoutRounding(DocumentNo);

        // TearDown: Set Zero on General Ledger Setup for Application Rounding Precision.
        ModifyGenLedgerSetup(ApplnRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowerPaymentWithApplRundng()
    var
        Amount: Decimal;
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        ExchRateAmount: Decimal;
    begin
        // Check that Application Rounding entry not Created in Detailed Ledger Entry after Post Invoice and Payment from General Journal
        // Lines Without currency and Modify General Ledger Setup for Appln. Rounding Precision.

        // Create and Post General Line for Invoice and Payment with currency, Modify Exchange Rate and Apply invoice.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2);
        ExchRateAmount := LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate());
        ApplyPaymentWithLowerValue(DocumentNo, CurrencyCode, -Amount, ExchRateAmount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LowerPaymentWithoutApplRundng()
    var
        Amount: Decimal;
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        ExchRateAmount: Decimal;
    begin
        // Check that Application Rounding entry not Created in Detailed Ledger Entry after Post Invoice and Payment from General Journal
        // Lines Without currency and Modify General Ledger Setup for Appln. Rounding Precision.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandInt(100);
        ExchRateAmount := Amount - LibraryUtility.GenerateRandomFraction();
        ApplyPaymentWithLowerValue(DocumentNo, CurrencyCode, -Amount, ExchRateAmount, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesFieldsValue()
    var
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        Amount: Decimal;
    begin
        // Check Application Rounding and Balance field's value on Apply Vendor Entries Page.

        // Setup: Create General Line for Invoice and Post with Random Values.
        Initialize();
        GeneralLedgerSetup.Get();
        SelectGenJournalBatch(GenJournalBatch);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, Vendor."No.", -LibraryRandom.RandInt(100),
          CreateAndModifyCurrency());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create Another general line for Payment with Posted Entry.
        Amount := GenJournalLine.Amount + GeneralLedgerSetup."Inv. Rounding Precision (LCY)";
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", -Amount,
          GenJournalLine."Currency Code");

        // Verify: Open Apply Vendor Entries page through General Journal and Verify Balance and Rounding Values with ApplyVendorEntriesPageHandler.
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Appln Rounding for Vendor");
        LibraryApplicationArea.EnableFoundationSetup();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Appln Rounding for Vendor");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Appln Rounding for Vendor");
    end;

    local procedure ApplyPaymentWithHigherValue(var DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; ExchRateAmt: Decimal; ApplyRoundingPrecision: Decimal)
    begin
        // Modify General Ledger Setup for Appl. Rounding Precision, Create Invoice, Payment and Post them and Apply with Currency.
        ApplyPaymentWithExchRate(DocumentNo, CurrencyCode, Amount, ExchRateAmt, ApplyRoundingPrecision);
    end;

    local procedure ApplyPaymentWithLowerValue(var DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; ExchRateAmt: Decimal; ApplyRoundingPrecision: Decimal)
    begin
        // Modify General Ledger Setup for Appl. Rounding Precision, Create Invoice, Payment and Post them and Apply
        // without Currency.
        ApplyPaymentWithExchRate(DocumentNo, CurrencyCode, Amount, ExchRateAmt, ApplyRoundingPrecision);

        // Verify: Verify that Application Rounding Entry not created on Detailed Ledger Entry.
        VerifyDetldLdgrWithoutRounding(DocumentNo);
    end;

    local procedure ApplyPaymentWithExchRate(var DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; ExchRateAmount: Decimal; ApplyRoundingPrecision: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Setup: Modify General Ledger Setup for Appl. Rounding Precision, Create Invoice, Payment and Post them and Apply with Currency.
        ModifyGenLedgerSetup(ApplyRoundingPrecision);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, Vendor."No.", Amount, CurrencyCode);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, Vendor."No.", ExchRateAmount, '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply Payment Against Invoice and Post it.
        ApplyAndPostVendorEntry(GenJournalLine."Document No.", ExchRateAmount);
        DocumentNo := GenJournalLine."Document No.";
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectionOfRemAmtWithCurrencyAmounts()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
    begin
        // Check that detailed vendor ledger entry with type Correction for Remaining Amount included into (Amount LCY)
        // and reconcile with G/L entries for receivables account

        // Create and Post General Line for Two Invoices and apply Payment with currency to both invoices
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 3, 3);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify();

        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", 2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply Payment Against Invoice and Post it.
        ApplyAndPostVendorPayment(GenJournalLine."Document No.");

        // Verify: Account Receivables amount should be -0.67, Correction amount should be 0.1
        VerifyCorrAmountGLEntries(Vendor, GenJournalLine."Document No.", 0.67, -0.01);
        VerifyCorrAmountVendLedgEntries(GenJournalLine."Document No.", 0.66);
        VerifyCorrAmountDtldVendLedgEntries(GenJournalLine."Document No.", -0.01);
    end;

    local procedure CreateAndModifyCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        // Take Random value for Application Rounding Precision.
        Currency.Get(CreateCurrency());
        Currency.Validate("Appln. Rounding Precision", LibraryRandom.RandDec(10, 2));
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);

        // Create Random Exchange Rate to keep the value lower from General Line's Exchange Rate Amount.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryUtility.GenerateRandomFraction());
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure ApplyAndPostVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, VendorLedgerEntry2."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ApplyAndPostVendorPayment(DocumentNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Payment, DocumentNo);
        VendLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendLedgerEntry, VendLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        VendLedgerEntry2.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgerEntry2.SetRange("Vendor No.", VendLedgerEntry."Vendor No.");
        VendLedgerEntry2.SetRange("Document Type", VendLedgerEntry2."Document Type"::Invoice);
        VendLedgerEntry2.SetRange(Open, true);
        if VendLedgerEntry2.FindSet() then
            repeat
                LibraryERM.SetAppliestoIdVendor(VendLedgerEntry2);
            until VendLedgerEntry2.Next() = 0;

        // Post Application Entries.
        LibraryERM.PostVendLedgerApplication(VendLedgerEntry);
    end;

    local procedure FindDetailedLedgerEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DocumentNo: Code[20])
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Appln. Rounding");
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
    end;

    [Normal]
    local procedure ModifyGenLedgerSetup(ApplnRoundingPrecision: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure VerifyDetailedLedgerEntry(DocumentNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Currency: Record Currency;
    begin
        FindDetailedLedgerEntry(DetailedVendorLedgEntry, DocumentNo);
        DetailedVendorLedgEntry.FindFirst();
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(Amount, DetailedVendorLedgEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, DetailedVendorLedgEntry.FieldCaption(Amount), Amount, DetailedVendorLedgEntry.TableCaption()));
    end;

    local procedure VerifyDetldLdgrWithoutRounding(DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindDetailedLedgerEntry(DetailedVendorLedgEntry, DocumentNo);
        Assert.IsFalse(DetailedVendorLedgEntry.FindFirst(), 'Application Rounding entry should not present.');
    end;

    local procedure VerifyCorrAmountGLEntries(Vendor: Record Vendor; DocumentNo: Code[20]; PayablesAmount: Decimal; CorrectionAmount: Decimal)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", VendorPostingGroup."Payables Account");
        GLEntry.Find('-');
        Assert.AreEqual(PayablesAmount, GLEntry.Amount, StrSubstNo('G/L payables amount should be %1', PayablesAmount));
        GLEntry.Next();
        Assert.AreEqual(CorrectionAmount, GLEntry.Amount, StrSubstNo('G/L correction amount should be %1.', CorrectionAmount));
    end;

    local procedure VerifyCorrAmountVendLedgEntries(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Payment);
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.FindFirst();
        VendLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreEqual(
          ExpectedAmount, VendLedgerEntry."Amount (LCY)",
          StrSubstNo('Amount (LCY) in payment customer entry should be %1.', ExpectedAmount));
    end;

    local procedure VerifyCorrAmountDtldVendLedgEntries(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendLedgEntry.SetRange("Document Type", DetailedVendLedgEntry."Document Type"::Payment);
        DetailedVendLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::"Correction of Remaining Amount");
        DetailedVendLedgEntry.FindLast();
        Assert.AreEqual(ExpectedAmount,
          DetailedVendLedgEntry."Amount (LCY)",
          StrSubstNo('Correction of remaining Amount (LCY) should be %1', ExpectedAmount));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Take Zero for Validation on Apply Customer Entries Page.
        GeneralLedgerSetup.Get();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        Assert.AreEqual(
          0, ApplyVendorEntries.ApplnRounding.AsDecimal(),
          StrSubstNo(AmountError, ApplyVendorEntries.ApplnRounding.Caption, 0, ApplyVendorEntries.Caption));
        Assert.AreEqual(
          -GeneralLedgerSetup."Inv. Rounding Precision (LCY)", ApplyVendorEntries.ControlBalance.AsDecimal(),
          StrSubstNo(
            AmountError, ApplyVendorEntries.ControlBalance.Caption, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
            ApplyVendorEntries.Caption));
    end;
}

