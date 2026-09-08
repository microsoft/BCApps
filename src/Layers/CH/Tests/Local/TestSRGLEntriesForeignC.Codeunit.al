codeunit 144026 "Test SR G/L Entries Foreign C."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryCH: Codeunit "Library - CH";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        Assert: Codeunit Assert;
        IncorrectSourceCurrencyAmountErr: Label 'Source Currency Amount on G/L entry for account %1 is incorrect.', Comment = '%1 = G/L Account No.';

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,GLAccountCreationMessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyGLEntriesForeignCurrencyReportWithNoConstraints()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
    begin
        // Setup
        Initialize();
        SetupTestData(GenJournalLine, GLAccountNo);

        // Execute report
        LibraryVariableStorage.Enqueue('');
        Commit();

        REPORT.Run(REPORT::"SR G/L Entries Foreign Currenc", true);

        // Verify data
        VerifyReportData(GenJournalLine, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,GLAccountCreationMessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyGLEntriesForeignCurrencyReportWithGLRegisterInput()
    var
        GLRegisterLine: Record "G/L Register";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
    begin
        // Setup
        Initialize();
        SetupTestData(GenJournalLine, GLAccountNo);

        // Execute report
        GLRegisterLine.FindLast();
        LibraryVariableStorage.Enqueue(GLRegisterLine."No.");
        Commit();

        REPORT.Run(REPORT::"SR G/L Entries Foreign Currenc", true);

        // Verify data
        VerifyReportData(GenJournalLine, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,GLAccountCreationMessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyGLEntriesForeignCurrencyReportWithFilter()
    var
        GLRegisterLine: Record "G/L Register";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
    begin
        // Setup
        Initialize();
        SetupTestData(GenJournalLine, GLAccountNo);

        // Execute report
        GLRegisterLine.FindLast();
        LibraryVariableStorage.Enqueue('');
        Commit();

        REPORT.Run(REPORT::"SR G/L Entries Foreign Currenc", true, false, GLRegisterLine);

        // Verify data
        VerifyReportData(GenJournalLine, GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySourceCurrencyVATAmountOnForeignPurchaseVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Currency: Record Currency;
        CurrencyCode: Code[10];
        ExpenseAccountNo: Code[20];
        VATPct: Decimal;
        GrossAmount: Decimal;
        ExpectedNet: Decimal;
        ExpectedVAT: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 647818] Source-currency VAT G/L entry of a foreign-currency purchase must carry the VAT amount, not the net amount.
        Initialize();

        // [GIVEN] A foreign currency (1:1 rate) and source-currency posting on both the expense and the purchase VAT account
        VATPct := 25;
        GrossAmount := 1000;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, 1, 1);
        Currency.Get(CurrencyCode);
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryCH.CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", '', '');
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Modify(true);
        ExpenseAccountNo := CreateGLAccount(GeneralPostingSetup, VATPostingSetup, CurrencyCode);
        SetSourceCurrencyPosting(VATPostingSetup."Purchase VAT Account", CurrencyCode);

        // [GIVEN] A purchase general journal line in the foreign currency for a VAT-inclusive amount
        CreatePurchaseJnlLineFCY(GenJournalLine, ExpenseAccountNo, CurrencyCode, VATPostingSetup, GrossAmount);

        // [WHEN] The journal line is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The expense G/L entry keeps the net amount and the VAT G/L entry keeps the VAT amount, both in source currency
        ExpectedNet := Round(GrossAmount / (1 + VATPct / 100), Currency."Amount Rounding Precision");
        ExpectedVAT := GrossAmount - ExpectedNet;
        VerifySourceCurrencyAmount(GenJournalLine."Document No.", ExpenseAccountNo, ExpectedNet);
        VerifySourceCurrencyAmount(GenJournalLine."Document No.", VATPostingSetup."Purchase VAT Account", ExpectedVAT);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure SetSourceCurrencyPosting(GLAccountNo: Code[20]; CurrencyCode: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Source Currency Posting", GLAccount."Source Currency Posting"::"Same Currency");
        GLAccount.Validate("Source Currency Code", CurrencyCode);
        GLAccount.Modify(true);
    end;

    local procedure CreatePurchaseJnlLineFCY(var GenJournalLine: Record "Gen. Journal Line"; ExpenseAccountNo: Code[20]; CurrencyCode: Code[10]; VATPostingSetup: Record "VAT Posting Setup"; GrossAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryCostAccounting.SetupGeneralJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", ExpenseAccountNo, GrossAmount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure VerifySourceCurrencyAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedSrcCurrAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreEqual(
            ExpectedSrcCurrAmount, GLEntry."Source Currency Amount",
            StrSubstNo(IncorrectSourceCurrencyAmountErr, GLAccountNo));
    end;

    [Normal]
    local procedure SetupTestData(var GenJournalLine: Record "Gen. Journal Line"; var GLAccountNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ExchangeRate: Decimal;
        AdjustmentExchangeRate: Decimal;
        CurrencyCode: Code[10];
    begin
        // Create new Currency
        ExchangeRate := LibraryRandom.RandDec(10, 2);
        AdjustmentExchangeRate := LibraryRandom.RandDec(10, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, ExchangeRate, AdjustmentExchangeRate);

        // Create General and VAT Posting setup
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryCH.CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          '', '');
        GLAccountNo := CreateGLAccount(GeneralPostingSetup, VATPostingSetup, CurrencyCode);

        // Initialize test data: create and post a General Journal Line
        LibraryCostAccounting.CreateJnlLine(GenJournalLine, GLAccountNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure VerifyReportData(GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();

        // Filter rows by GL Account No.
        LibraryReportDataset.SetRange('Description_GLEntry', GLAccountNo);
        LibraryReportDataset.GetNextRow();

        // Verify the XML for the proper entry values.
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GLEntry', GenJournalLine."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GLEntryFCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('GlAccCurrencyCode', GenJournalLine."Currency Code");
    end;

    local procedure CreateGLAccount(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        if CurrencyCode <> '' then
            GLAccount.Validate("Source Currency Posting", GLAccount."Source Currency Posting"::"Same Currency");
        GLAccount.Validate("Source Currency Code", CurrencyCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportRequestPageHandler(var GLEntriesForeginCurrency: TestRequestPage "SR G/L Entries Foreign Currenc")
    var
        GLRegisterNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(GLRegisterNo);

        // If the dequeued variable is not empty, it will be used as an input value for the report
        if Format(GLRegisterNo) <> '' then
            GLEntriesForeginCurrency."FromGlRegister.""No.""".SetValue(GLRegisterNo);

        // Save the report as XML
        GLEntriesForeginCurrency.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure GLAccountCreationMessageHandler(Message: Text[1024])
    begin
    end;
}
