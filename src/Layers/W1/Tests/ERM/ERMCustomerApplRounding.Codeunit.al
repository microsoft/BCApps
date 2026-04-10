codeunit 134901 "ERM Customer Appl Rounding"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Application Rounding] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ApplnRoundPrecMessage: Label '%1 must be %2 in %3 %4=%5.';
        ApplyEntryMessage: Label '%1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplRoundingWithCurrency()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        ApplRoundingAmountLCY: Decimal;
    begin
        // Check that correct Application Rounding Amount Applied after posting General Journal Line with FCY and making Payment against it.

        // Setup: Create Customer and Update Currency.
        Initialize();
        Currency.Get(UpdateCurrency(CreateCurrencyForApplRounding(), LibraryRandom.RandInt(9) / 100));

        // Using value for calculating Application Rounding Amount.
        ApplRoundingAmountLCY := LibraryERM.ConvertCurrency(Currency."Appln. Rounding Precision", Currency.Code, '', WorkDate());

        // Create and Post Invoice and Payment Line.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(300), CreateCustomer(),
          CreateCurrencyForApplRounding());
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          -GenJournalLine.Amount - Currency."Appln. Rounding Precision", GenJournalLine."Account No.", Currency.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Post Customer Ledger Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.");

        // Verify: Verify Remaining Amount of Customer Ledger Entry.
        VerifyApplnRoundingPrecision(GenJournalLine."Document No.", ApplRoundingAmountLCY);
        VerifyCustomerLedgerEntry(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplRoundingWithGLSetup()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApplRoundingAmount: Decimal;
        ApplnRoundingPrecisionAmount: Decimal;
    begin
        // Check that correct Application Rounding Amount Applied after posting General Journal Line with LCY and making Payment against it.

        // Setup: Create Customer and Update General Ledger setup.
        Initialize();
        ApplnRoundingPrecisionAmount := UpdateGeneralLedgerSetup(GeneralLedgerSetup, LibraryRandom.RandInt(9) / 100);
        ApplRoundingAmount := GeneralLedgerSetup."Appln. Rounding Precision";

        // Create and Post Invoice and Payment Line.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(300), CreateCustomer(),
          CreateCurrencyForApplRounding());
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, -GenJournalLine."Amount (LCY)" -
          GeneralLedgerSetup."Appln. Rounding Precision", GenJournalLine."Account No.", '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Post Customer Ledger Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.");

        // Verify: Verify Remaining Amount of Customer Ledger Entry.
        VerifyApplnRoundingPrecision(GenJournalLine."Document No.", ApplRoundingAmount);
        VerifyCustomerLedgerEntry(GenJournalLine."Document No.");

        // TearDown: Roll back the Previous General Ledger Setup.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup, ApplnRoundingPrecisionAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectionOfRemAmtWithCurrency()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        Amount: Decimal;
    begin
        // Check that an Entry of Entry Type Correction of Remaining Amount created after posting General Journal Line
        // with FCY and making Payment against it.

        // Setup: Create Customer and Update Currency.
        Initialize();

        // Fix the value of Application Rounding Precision because without fixing this value we are not able to generate
        // a Correction Entry.On Random value of Application Rounding Precision we are not able to find Correction Amount value.
        Currency.Get(UpdateCurrency(CreateCurrencyCorrectionEntry(), 0.05));

        // Create and Post Invoice and Payment Line.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(300),
          CreateCustomer(), CreateCurrencyCorrectionEntry());
        Amount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", Currency.Code, WorkDate());
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment,
          -Amount + Currency."Appln. Rounding Precision", GenJournalLine."Account No.", Currency.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Post Customer Ledger Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.");

        // Verify: Verify Remaining Amount of Customer Ledger Entry.
        VerifyCorrectionofRemAmount(GenJournalLine."Document No.");
        VerifyCustomerLedgerEntry(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectionOfRemAmtWithCurrencyAmounts()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
    begin
        // Check that detailed customer ledger entry with type Correction for Remaining Amount included into (Amount LCY)
        // and reconcile with G/L entries for receivables account

        // Create and Post General Line for Two Invoices and apply Payment with currency to both invoices
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 3, 3);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify();

        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", 1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply Payment Against Invoice and Post it.
        ApplyAndPostCustomerPayment(GenJournalLine."Document No.");

        // Verify: Account Receivables amount should be -0.67, Correction amount should be 0.1
        VerifyCorrAmountGLEntries(Customer, GenJournalLine."Document No.", -0.67, 0.01);
        VerifyCorrAmountCustLedgEntries(GenJournalLine."Document No.", -0.66);
        VerifyCorrAmountDtldCustLedgEntries(GenJournalLine."Document No.", 0.01);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesFieldsValue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        Amount: Decimal;
    begin
        // Check Application Rounding and Balance field's value on Apply Customer Entries Page.

        // Setup: Create General Line for Invoice and Post with Random Values.
        Initialize();
        GeneralLedgerSetup.Get();
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(100), CreateCustomer(),
          CreateAndModifyCurrency());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create Another general line for Payment with Posted Entry.
        Amount := GenJournalLine.Amount - GeneralLedgerSetup."Inv. Rounding Precision (LCY)";
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, -Amount, GenJournalLine."Account No.",
          GenJournalLine."Currency Code");

        // Verify: Open Apply Customer Entries page through General Journal and Verify Balance and Rounding Values with ApplyCustomerEntriesPageHandler.
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Customer Appl Rounding");
        LibraryApplicationArea.EnableFoundationSetup();

        // Setup demo data.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Customer Appl Rounding");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Customer Appl Rounding");
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Invoice, DocumentNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

        // Post Application Entries.
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostCustomerPayment(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        CustLedgerEntry2.SetCurrentKey("Customer No.", Open, Positive);
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.SetRange("Document Type", CustLedgerEntry2."Document Type"::Invoice);
        CustLedgerEntry2.SetRange(Open, true);
        if CustLedgerEntry2.FindSet() then
            repeat
                LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
            until CustLedgerEntry2.Next() = 0;

        // Post Application Entries.
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateAndModifyCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        // Take Random value for Application Rounding Precision.
        Currency.Get(CreateCurrencyForApplRounding());
        Currency.Validate("Appln. Rounding Precision", LibraryRandom.RandDec(10, 2));
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
    end;

    local procedure CreateCurrencyForApplRounding(): Code[10]
    var
        Currency: Record Currency;
    begin
        CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyCorrectionEntry(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(CreateCurrencyForApplRounding());
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always Half than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" / 2);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        // Select Journal Batch Name.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateCurrency(CurrencyCode: Code[10]; ApplnRoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure UpdateGeneralLedgerSetup(var GeneralLedgerSetup: Record "General Ledger Setup"; ApplnRoundingPrecisionAmount: Decimal) ApplnRoundingPrecision: Decimal
    begin
        GeneralLedgerSetup.Get();
        ApplnRoundingPrecision := GeneralLedgerSetup."Appln. Rounding Precision";
        GeneralLedgerSetup.Validate("Appln. Rounding Precision", ApplnRoundingPrecisionAmount);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyApplnRoundingPrecision(DocumentNo: Code[20]; ApplnRoundPrecAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Appln. Rounding");
        DetailedCustLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          DetailedCustLedgEntry."Amount (LCY)", ApplnRoundPrecAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(ApplnRoundPrecMessage, DetailedCustLedgEntry.FieldCaption("Amount (LCY)"), DetailedCustLedgEntry."Amount (LCY)",
            DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    local procedure VerifyCorrectionofRemAmount(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount");
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount");
            Assert.AreNearlyEqual(
              0, CustLedgerEntry."Remaining Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
              StrSubstNo(ApplnRoundPrecMessage, CustLedgerEntry.FieldCaption("Amount (LCY)"), CustLedgerEntry."Amount (LCY)",
                CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyCorrAmountGLEntries(Customer: Record Customer; DocumentNo: Code[20]; ReceivablesAmount: Decimal; CorrectionAmount: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Receivables Account");
        GLEntry.Find('-');
        Assert.AreEqual(ReceivablesAmount, GLEntry.Amount, StrSubstNo('G/L receivables amount should be %1', ReceivablesAmount));
        GLEntry.Next();
        Assert.AreEqual(CorrectionAmount, GLEntry.Amount, StrSubstNo('G/L correction amount should be %1.', CorrectionAmount));
    end;

    local procedure VerifyCorrAmountCustLedgEntries(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreEqual(
          ExpectedAmount, CustLedgerEntry."Amount (LCY)",
          StrSubstNo('Amount (LCY) in payment customer entry should be %1.', ExpectedAmount));
    end;

    local procedure VerifyCorrAmountDtldCustLedgEntries(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Correction of Remaining Amount");
        DetailedCustLedgEntry.FindLast();
        Assert.AreEqual(
          ExpectedAmount, DetailedCustLedgEntry."Amount (LCY)",
          StrSubstNo('Correction of remaining Amount (LCY) should be %1', ExpectedAmount));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Take Zero for Validation on Apply Customer Entries Page.
        GeneralLedgerSetup.Get();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        Assert.AreEqual(
          0, ApplyCustomerEntries.ApplnRounding.AsDecimal(),
          StrSubstNo(ApplyEntryMessage, ApplyCustomerEntries.ApplnRounding.Caption, 0, ApplyCustomerEntries.Caption));
        Assert.AreEqual(
          GeneralLedgerSetup."Inv. Rounding Precision (LCY)", ApplyCustomerEntries.ControlBalance.AsDecimal(),
          StrSubstNo(
            ApplyEntryMessage, ApplyCustomerEntries.ControlBalance.Caption, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
            ApplyCustomerEntries.Caption));
    end;
}

