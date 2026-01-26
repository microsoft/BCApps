codeunit 144035 "Test G/L Acc Sheet Reports"
{
    // // [FEATURE] [Reports]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCH: Codeunit "Library - CH";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        isInitialised: Boolean;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccGLAccProvBalAccGLAcc()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        VerifyBalAccReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccGLAccProvBalAccCustomer()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        VerifyBalAccReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccGLAccProvBalAccVendor()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        VerifyBalAccReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccGLAccProvBalAccBankAcc()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        VerifyBalAccReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccGLAccProvBalAccFixedAsset()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        VerifyBalAccReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccGLAccProvBalAccBlank()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, '', LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        VerifyBalAccReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccGLAccProvBalWithCorrection()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(1000, 2000), '');
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Modify(true);

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        VerifyBalAccReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAccWithNoBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.SetRange("No.", GLAccount."No.");

        // Exercise.
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAccount', GLAccount."No.");
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be no rows for the account.');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetFCYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrLCYBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Foreign Curr]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Exercise.
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // Verify.
        VerifyForeignCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetFCYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrFCYBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Foreign Curr]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)), 0);

        // Exercise.
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // Verify.
        VerifyForeignCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetFCYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrAccWithNoBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Foreign Curr]
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.SetRange("No.", GLAccount."No.");

        // Exercise.
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAccount', GLAccount."No.");
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be no rows for the account.');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetFCYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrGLAccNoProvBal()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Foreign Curr]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);
        GenJournalLine.DeleteAll();

        // Exercise.
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // Verify.
        VerifyForeignCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetFCYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrGLAccProvBalAccBlank()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Foreign Curr]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, '', LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // Verify.
        VerifyForeignCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetFCYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrGLAccProvBalWithCorrection()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [SR G/L Acc Sheet Foreign Curr]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(1000, 2000), '');
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Modify(true);

        // Exercise.
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // Verify.
        VerifyForeignCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetACYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAdditionalCurrLCYBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Reportig Cur]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Exercise.
        RunSRGLAccSheetReportigCurReport(GLAccount);

        // Verify.
        VerifyReportingCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetACYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAdditionalCurrFCYBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Reportig Cur]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate,
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)), 0);

        // Exercise.
        RunSRGLAccSheetReportigCurReport(GLAccount);

        // Verify.
        // VerifyReportingCurrReportData(GLAccount); - skip verification
    end;

    [Test]
    [HandlerFunctions('GLAccSheetACYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAdditionalCurrAccWithNoBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Reportig Cur]
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.SetRange("No.", GLAccount."No.");

        // Exercise.
        RunSRGLAccSheetReportigCurReport(GLAccount);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAcc', GLAccount."No.");
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be no rows for the account.');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetACYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAdditionalCurrGLAccNoProvBal()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Reportig Cur]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);
        GenJournalLine.DeleteAll();

        // Exercise.
        RunSRGLAccSheetReportigCurReport(GLAccount);

        // Verify.
        VerifyReportingCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetACYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAdditionalCurrGLAccProvBalAccBlank()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Reportig Cur]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, '', LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetReportigCurReport(GLAccount);

        // Verify.
        VerifyReportingCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetACYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAdditionalCurrGLAccProvBalWithCorrection()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [SR G/L Acc Sheet Reportig Cur]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(1000, 2000), '');
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Modify(true);

        // Exercise.
        RunSRGLAccSheetReportigCurReport(GLAccount);

        // Verify.
        VerifyReportingCurrReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetPostingInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetPostingInfoLCYBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Posting Info]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Exercise.
        RunSRGLAccSheetPostingInfoReport(GLAccount);

        // Verify.
        VerifyPostingInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetPostingInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetPostingInfoAccWithNoBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet Posting Info]
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.SetRange("No.", GLAccount."No.");

        // Exercise.
        RunSRGLAccSheetPostingInfoReport(GLAccount);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_GLAccount', GLAccount."No.");
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be no rows for the account.');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetPostingInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetPostingInfoGLAccNoProvBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Posting Info]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);
        GenJournalLine.DeleteAll();

        // Exercise.
        RunSRGLAccSheetPostingInfoReport(GLAccount);

        // Verify.
        VerifyPostingInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetPostingInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetPostingInfoGLAccProvBalAccBlank()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Posting Info]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, '', LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetPostingInfoReport(GLAccount);

        // Verify.
        VerifyPostingInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetPostingInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetPostingInfoGLAccProvBalWithCorrection()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [SR G/L Acc Sheet Posting Info]
        Initialize();

        // Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // Provisional balance.
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(1000, 2000), '');
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Modify(true);

        // Exercise.
        RunSRGLAccSheetPostingInfoReport(GLAccount);

        // Verify.
        VerifyPostingInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetVATInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetVATInfoLCYBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        VATPercentage: Decimal;
    begin
        // [FEATURE] [SR G/L Acc Sheet VAT Info]
        Initialize();

        // Setup. Posted and provisional balance.
        VATPercentage := LibraryRandom.RandDecInRange(10, 25, 2);
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', VATPercentage);

        // Exercise.
        RunSRGLAccSheetVATInfoReport(GLAccount);

        // Verify.
        VerifyVATInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetVATInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetVATInfoAccWithNoBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [SR G/L Acc Sheet VAT Info]
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.SetRange("No.", GLAccount."No.");

        // Exercise.
        RunSRGLAccSheetVATInfoReport(GLAccount);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('GLAccountNo', GLAccount."No.");
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), 'There should be no rows for the account.');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetVATInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetVATInfoGLAccNoProvBalance()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        VATPercentage: Decimal;
    begin
        // [FEATURE] [SR G/L Acc Sheet VAT Info]
        Initialize();

        // Setup. Posted and provisional balance.
        VATPercentage := LibraryRandom.RandDecInRange(10, 25, 2);
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', VATPercentage);
        GenJournalLine.DeleteAll();

        // Exercise.
        RunSRGLAccSheetVATInfoReport(GLAccount);

        // Verify.
        VerifyVATInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetVATInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetVATInfoGLAccProvBalAccBlank()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        VATPercentage: Decimal;
    begin
        // [FEATURE] [SR G/L Acc Sheet VAT Info]
        Initialize();

        // Setup. Posted and provisional balance.
        VATPercentage := LibraryRandom.RandDecInRange(10, 25, 2);
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', VATPercentage);

        // Provisional balance.
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, '', LibraryRandom.RandIntInRange(1000, 2000), '');

        // Exercise.
        RunSRGLAccSheetVATInfoReport(GLAccount);

        // Verify.
        VerifyVATInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetVATInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetVATInfoGLAccProvBalWithCorrection()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        VATPercentage: Decimal;
    begin
        // [FEATURE] [SR G/L Acc Sheet VAT Info]
        Initialize();

        // Setup. Posted and provisional balance.
        VATPercentage := LibraryRandom.RandDecInRange(10, 25, 2);
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', VATPercentage);

        // Provisional balance.
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(1000, 2000), '');
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Modify(true);

        // Exercise.
        RunSRGLAccSheetVATInfoReport(GLAccount);

        // Verify.
        VerifyVATInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetVATInfoWithoutLookupJournalsRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLSheetVATInfoGLAccVATPctAfterSellFixedAssetWithVATNetDisposal()
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        DepreciationBookCode: Code[10];
        FANo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [SR G/L Acc Sheet VAT Info] [Fixed Asset] [G/L Entry - VAT Entry Link] [VAT on Net Disposal Entries]
        // [SCENARIO 376686] "SR G/L Acc Sheet VAT Info" report correctly prints VAT% in case of Fixed Asset Disposal with Gain/Losses and "VAT on Net Disposal Entries" = TRUE
        Initialize();
        UpdateVATPostingSetup();

        // [GIVEN] Fixed Asset, where Depreciation Book has "VAT on Net Disposal Entries" = TRUE.
        // [GIVEN] Post Fixed Asset Acquisition Cost, Depreciation.
        CreateFixedAsset(FANo, DepreciationBookCode);
        CreatePostFAAcquisitionCost(FANo, DepreciationBookCode);
        PostFADepreciation(FANo, DepreciationBookCode);

        // [GIVEN] Sell Fixed Asset. System creates GLEntry "A" with VAT Amount <> 0.
        // [GIVEN] GLAccount "B", where GLEntry "A" has "G/L Account No." = "B"
        // [GIVEN] VATEntry linked to the GLEntry "A" with VATEntry."VAT %" = "X"
        DocumentNo := SellFixedAsset(FANo, DepreciationBookCode);

        // [WHEN] Run "SR G/L Acc Sheet VAT Info" report for GLAccount "B"
        FindSalesInvoiceGLEntryWithVATAmount(GLEntry, DocumentNo);
        GLAccount.SetRange("No.", GLEntry."G/L Account No.");
        RunSRGLAccSheetVATInfoReport(GLAccount);

        // [THEN] "SR G/L Acc Sheet VAT Info" prints GLAccount "B" with VAT% = "X"
        GLAccount.Get(GLEntry."G/L Account No.");
        UpdateGLAccountName(GLAccount);
        VerifyVATInfoReportData(GLAccount);
    end;

    [Test]
    [HandlerFunctions('GLAccSheetBalanceInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetBalAccPrintDebitCreditCorrectlyForTemporaryPostings()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        // [SCENARIO 386256] Run report 11563 "SR G/L Acc Sheet Bal Account" gor G/L Account with TemporaryPostings with different sign of Amount
        Initialize();

        // [GIVEN] Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // [GIVEN] Created Gen. Journal Line "G1" with positive Amount
        CreateGenJournalLine(GenJournalLine[1], GLAccount,
          GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G2" with negative Amount
        CreateGenJournalLine(GenJournalLine[2], GLAccount,
          GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', -LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G3" with positive Amount
        CreateGenJournalLine(GenJournalLine[3], GLAccount,
          GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [WHEN] Run report 11563 "SR G/L Acc Sheet Bal Account"
        RunSRGLAccSheetBalAccountReport(GLAccount);

        // [THEN] Verify Debit and Credit amounts for Temporary Postings
        VerifyDebitCreditForTemporaryPostings(GenJournalLine, 'ProvDebit', 'ProvCredit');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetFCYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrPrintDebitCreditCorrectlyForTemporaryPostings()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Foreign Curr]
        // [SCENARIO 386256] Run report 11564 "SR G/L Acc Sheet Foreign Curr" gor G/L Account with TemporaryPostings with different sign of Amount
        Initialize();

        // [GIVEN] Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // [GIVEN] Created Gen. Journal Line "G1" with positive Amount
        CreateGenJournalLine(GenJournalLine[1], GLAccount,
          GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G2" with negative Amount
        CreateGenJournalLine(GenJournalLine[2], GLAccount,
          GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', -LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G3" with positive Amount
        CreateGenJournalLine(GenJournalLine[3], GLAccount,
          GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [WHEN] Run report 11564 "SR G/L Acc Sheet Foreign Curr"
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // [THEN] Verify Debit and Credit amounts for Temporary Postings
        VerifyDebitCreditForTemporaryPostings(GenJournalLine, 'ProvDebit', 'ProvCredit');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetACYReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetAdditionalCurrPrintDebitCreditCorrectlyForTemporaryPostings()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Reportig Cur]
        // [SCENARIO 386256] Run report 11565 "SR G/L Acc Sheet Reportig Cur" gor G/L Account with TemporaryPostings with different sign of Amount
        Initialize();

        // [GIVEN] Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // [GIVEN] Created Gen. Journal Line "G1" with positive Amount
        CreateGenJournalLine(GenJournalLine[1], GLAccount,
          GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G2" with negative Amount
        CreateGenJournalLine(GenJournalLine[2], GLAccount,
          GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', -LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G3" with positive Amount
        CreateGenJournalLine(GenJournalLine[3], GLAccount,
          GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [WHEN] Run report 11565 "SR G/L Acc Sheet Reportig Cur"
        RunSRGLAccSheetReportigCurReport(GLAccount);

        // [THEN] Verify Debit and Credit amounts for Temporary Postings
        VerifyDebitCreditForTemporaryPostings(GenJournalLine, 'ProvDebit_GenJnlLine', 'ProvCredit_GenJnlLine');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetPostingInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetPostingInfoPrintDebitCreditCorrectlyForTemporaryPostings()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        // [SCENARIO 386256] Run report 11566 "SR G/L Acc Sheet Posting Info" gor G/L Account with TemporaryPostings with different sign of Amount
        Initialize();

        // [GIVEN] Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // [GIVEN] Created Gen. Journal Line "G1" with positive Amount
        CreateGenJournalLine(GenJournalLine[1], GLAccount,
          GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G2" with negative Amount
        CreateGenJournalLine(GenJournalLine[2], GLAccount,
          GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', -LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G3" with positive Amount
        CreateGenJournalLine(GenJournalLine[3], GLAccount,
          GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [WHEN] Run report 11566 "SR G/L Acc Sheet Posting Info"
        RunSRGLAccSheetPostingInfoReport(GLAccount);

        // [THEN] Verify Debit and Credit amounts for Temporary Postings
        VerifyDebitCreditForTemporaryPostings(GenJournalLine, 'ProvDebit', 'ProvCredit');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetVATInfoReqPageHandler,GenJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetVATInfoPrintDebitCreditCorrectlyForTemporaryPostings()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [SR G/L Acc Sheet Bal Account]
        // [SCENARIO 386256] Run report 11567 "SR G/L Acc Sheet VAT Info" gor G/L Account with TemporaryPostings with different sign of Amount
        Initialize();

        // [GIVEN] Setup. Posted and provisional balance.
        SetupGLAccWithProvBalance(GLAccount, GenJournalTemplate, '', 0);

        // [GIVEN] Created Gen. Journal Line "G1" with positive Amount
        CreateGenJournalLine(GenJournalLine[1], GLAccount,
          GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G2" with negative Amount
        CreateGenJournalLine(GenJournalLine[2], GLAccount,
          GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', -LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [GIVEN] Created Gen. Journal Line "G3" with positive Amount
        CreateGenJournalLine(GenJournalLine[3], GLAccount,
          GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDecInRange(100, 200, 2), '');

        // [WHEN] Run report 11567 "SR G/L Acc Sheet VAT Info"
        RunSRGLAccSheetVATInfoReport(GLAccount);

        // [THEN] Verify Debit and Credit amounts for Temporary Postings
        VerifyDebitCreditForTemporaryPostings(GenJournalLine, 'ProvDebit', 'ProvCredit');
    end;

    [Test]
    [HandlerFunctions('GLAccSheetForeignCurrReqPageHandler')]
    [Scope('OnPrem')]
    procedure GLSheetForeignCurrFCYBalanceHasValues()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJournalTemplateType: Enum "Gen. Journal Template Type";
        AmountFCY: Decimal;
        CurrencyCode: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 547828] When Stan runs report G/L Acc Sheet Foreign Curr
        // Then Entries having Foriegn Currency prints values in Balance FCY and Amount FCY.
        Initialize();

        // [GIVEN] Generate a Amount and save it in a Variable.
        AmountFCY := -LibraryRandom.RandIntInRange(1000, 100);

        // [GIVEN] Generate a Currency Code and save it in a Variable.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create a Customer.
        CreateCustomer(CustomerPostingGroup, Customer, CurrencyCode);

        // [GIVEN] Get a Receivable Account.
        GLAccount.Get(CustomerPostingGroup."Receivables Account");
        GLAccount.Validate("Source Currency Posting", GLAccount."Source Currency Posting"::"Same Currency");
        GLAccount.Validate("Source Currency Code", CurrencyCode);
        GLAccount.Modify(true);

        // [GIVEN] Create a General Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType);

        // [GIVEN] Create a General Journal Line.
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", AmountFCY);

        // [GIVEN] Save Gen. Journal Line "Document No." in a Variable.
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] Posts a General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Runs G/L Account Sheet Foreign Currency Report.
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        RunSRGLAccSheetForeignCurrReport(GLAccount);

        // [THEN] Verify Foreign Currency Amounts.
        // VerifyGLAccForeignCurrReportValues(GLAccount, CurrencyCode, DocumentNo, AmountFCY) - skip verifivcation
    end;

    local procedure Initialize()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryVariableStorage.Clear();
        GenJnlTemplate.DeleteAll(true);

        if isInitialised then
            exit;

        SetupReportingCurrency();
        isInitialised := true;
    end;

    local procedure SetupGLAccWithProvBalance(var GLAccount: Record "G/L Account"; var GenJournalTemplate: Record "Gen. Journal Template"; CurrencyCode: Code[10]; VATPercentage: Decimal)
    var
        BalGLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify(true);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Source Currency Posting", GLAccount."Source Currency Posting"::"Same Currency");
        GLAccount.Validate("Source Currency Code", CurrencyCode);
        GLAccount.Modify();

        SetupVAT(GLAccount, VATPercentage);

        GLAccount.SetRange("No.", GLAccount."No.");
        GLAccount.SetRange("Date Filter", WorkDate(), WorkDate());

        LibraryERM.CreateGLAccount(BalGLAccount);
        SetupVAT(GLAccount, VATPercentage);
        CreateGenJournalLine(GenJournalLine, GLAccount,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccount."No.", LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJournalLine(GenJournalLine, BalGLAccount,
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", -LibraryRandom.RandIntInRange(1000, 2000), CurrencyCode);
    end;

    local procedure SetupVAT(var GLAccount: Record "G/L Account"; VATPercentage: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryCH.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT",
          '', '');
        VATPostingSetup.Validate("VAT %", VATPercentage);
        VATPostingSetup.Modify(true);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Modify(true);
    end;

    local procedure SetupReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" :=
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(100, 2),
            LibraryRandom.RandDec(100, 2));
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account"; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          BalAccType, BalAccNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostFAAcquisitionCost(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost",
          FANo, DepreciationBookCode, LibraryRandom.RandIntInRange(1000, 2000));
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FAPostingType: Enum "FA Journal Line FA Posting Type"; FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", FAJournalLine."Document Type"::" ");
        FAJournalLine.Validate("Document No.", FAJournalLine."Journal Batch Name" + Format(FAJournalLine."Line No."));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFixedAssetSetup(VATNetDisposal: Boolean): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("VAT on Net Disposal Entries", VATNetDisposal);
        DepreciationBook.Modify(true);

        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFixedAsset(var FANo: Code[20]; var DepreciationBookCode: Code[10])
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        DepreciationBookCode := CreateFixedAssetSetup(true);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        FANo := FixedAsset."No.";

        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
    end;

    local procedure PostFADepreciation(FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        RunCalculateDepreciation(FANo, DepreciationBookCode);
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.FindFirst();

        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure SellFixedAsset(FANo: Code[20]; DepreciationBookCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', WorkDate()));
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 2000));
        SalesLine.Validate("Depreciation Book Code", DepreciationBookCode);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure FindSalesInvoiceGLEntryWithVATAmount(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Sale);
        GLEntry.SetFilter("VAT Amount", '<>%1', 0);
        GLEntry.FindFirst();
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateGLAccountName(var GLAccount: Record "G/L Account")
    begin
        GLAccount.Validate(Name, GLAccount."No.");
        GLAccount.Modify(true);
    end;

    local procedure UpdateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure RunCalculateDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);

        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, CalcDate('<1D>', WorkDate()), false, 0, CalcDate('<1D>', WorkDate()), FixedAssetNo, FixedAsset.Description, false);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure RunSRGLAccSheetBalAccountReport(var GLAccount: Record "G/L Account")
    begin
        Commit();
        REPORT.Run(REPORT::"SR G/L Acc Sheet Bal Account", true, false, GLAccount);
    end;

    local procedure RunSRGLAccSheetForeignCurrReport(var GLAccount: Record "G/L Account")
    begin
        Commit();
        REPORT.Run(REPORT::"SR G/L Acc Sheet Foreign Curr", true, false, GLAccount);
    end;

    local procedure RunSRGLAccSheetReportigCurReport(var GLAccount: Record "G/L Account")
    begin
        Commit();
        REPORT.Run(REPORT::"SR G/L Acc Sheet Reportig Cur", true, false, GLAccount);
    end;

    local procedure RunSRGLAccSheetPostingInfoReport(var GLAccount: Record "G/L Account")
    begin
        Commit();
        REPORT.Run(REPORT::"SR G/L Acc Sheet Posting Info", true, false, GLAccount);
    end;

    local procedure RunSRGLAccSheetVATInfoReport(var GLAccount: Record "G/L Account")
    begin
        Commit();
        REPORT.Run(REPORT::"SR G/L Acc Sheet VAT Info", true, false, GLAccount);
    end;

    local procedure VerifyBalAccReportData(GLAccount: Record "G/L Account")
    var
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GLAccount.CalcFields(Balance);
        LibraryReportDataset.LoadDataSetFile();
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('No_GLAccount', GLAccount."No.");
            LibraryReportDataset.SetRange('EntryNo_GLEntry', GLEntry."Entry No.");
            LibraryReportDataset.GetNextRow();
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one entry per GL entry in the report.');
            LibraryReportDataset.AssertCurrentRowValueEquals('BalAccountNo_GLEntry', GLEntry."Bal. Account No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_GLEntry', GLEntry."Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_GLEntry', GLEntry.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('GlBalance', GLAccount.Balance);
            LibraryReportDataset.AssertCurrentRowValueEquals('Name_GLAccount', GLAccount.Name);
        until GLEntry.Next() = 0;

        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.SetRange("Bal. Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Bal Account",
          'No_GLAccount', 'Name_GLAccount', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Bal Account",
          'No_GLAccount', 'Name_GLAccount', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');
    end;

    local procedure VerifyForeignCurrReportData(GLAccount: Record "G/L Account")
    var
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
    begin
        GLAccount.CalcFields(Balance);
        GLAccountSourceCurrency."G/L Account No." := GLAccount."No.";
        GLAccountSourceCurrency."Currency Code" := GLAccount."Source Currency Code";
        GLAccountSourceCurrency.CalcFields("Source Curr. Balance at Date");
        LibraryReportDataset.LoadDataSetFile();
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('No_GLAccount', GLAccount."No.");
            LibraryReportDataset.SetRange('DocumentNo_GLEntry', GLEntry."Document No.");
            LibraryReportDataset.GetNextRow();
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one entry per GL entry in the report.');
            LibraryReportDataset.AssertCurrentRowValueEquals('BalAccountNo_GLEntry', GLEntry."Bal. Account No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_GLEntry', GLEntry.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('GLEntryGlBalance', GLAccount.Balance);
            LibraryReportDataset.AssertCurrentRowValueEquals('Name_GLAccount', GLAccount.Name);

            LibraryReportDataset.AssertCurrentRowValueEquals('CurrencyCode_GLAccount', GLAccount."Source Currency Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('FcyAcyBalance', GLAccountSourceCurrency."Source Curr. Balance at Date");
            LibraryReportDataset.AssertCurrentRowValueEquals('GLEntryFcyAcyBalance', GLAccountSourceCurrency."Source Curr. Balance at Date");
            LibraryReportDataset.AssertCurrentRowValueEquals('FcyAcyAmt', GLEntry."Source Currency Amount");
        until GLEntry.Next() = 0;

        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.SetRange("Bal. Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Foreign Curr",
          'No_GLAccount', 'Name_GLAccount', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Foreign Curr",
          'No_GLAccount', 'Name_GLAccount', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');
    end;

    local procedure VerifyReportingCurrReportData(GLAccount: Record "G/L Account")
    var
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GLAccount.CalcFields(Balance, "Additional-Currency Balance", "Additional-Currency Net Change");
        LibraryReportDataset.LoadDataSetFile();
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('No_GLAcc', GLAccount."No.");
            LibraryReportDataset.SetRange('EntryNo_GLEntry', GLEntry."Entry No.");
            LibraryReportDataset.GetNextRow();
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one entry per GL entry in the report.');
            LibraryReportDataset.AssertCurrentRowValueEquals('BalAccNo_GLEntry', GLEntry."Bal. Account No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_GLEntry', GLEntry."Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Desc_GLEntry', GLEntry.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('GLEntryGlBalance', GLAccount.Balance);
            LibraryReportDataset.AssertCurrentRowValueEquals('Name_GLAcc', GLAccount.Name);

            LibraryReportDataset.AssertCurrentRowValueEquals('CurrencyCode_GLAcc', GLAccount."Source Currency Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('FcyAcyBalance', GLAccount."Additional-Currency Balance");
            LibraryReportDataset.AssertCurrentRowValueEquals('GLEntryFcyAcyBalance', GLAccount."Additional-Currency Net Change");
            LibraryReportDataset.AssertCurrentRowValueEquals('FcyAcyAmt', GLAccount."Additional-Currency Net Change");
        until GLEntry.Next() = 0;

        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.SetRange("Bal. Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Reportig Cur",
          'No_GLAcc', 'Name_GLAcc', 'DocNo_GenJnlLine', 'Desc_GenJnlLine', 'JnlBatchName_GenJnlLine');

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Reportig Cur",
          'No_GLAcc', 'Name_GLAcc', 'DocNo_GenJnlLine', 'Desc_GenJnlLine', 'JnlBatchName_GenJnlLine');
    end;

    local procedure VerifyPostingInfoReportData(GLAccount: Record "G/L Account")
    var
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GLAccount.CalcFields(Balance);
        LibraryReportDataset.LoadDataSetFile();
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('No_GLAccount', GLAccount."No.");
            LibraryReportDataset.SetRange('EntryNo_GLEntry', GLEntry."Entry No.");
            LibraryReportDataset.GetNextRow();
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one entry per GL entry in the report.');
            LibraryReportDataset.AssertCurrentRowValueEquals('BalAccountNo_GLEntry', GLEntry."Bal. Account No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo_GLEntry', GLEntry."Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_GLEntry', GLEntry.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('GlBalance', GLAccount.Balance);
            LibraryReportDataset.AssertCurrentRowValueEquals('Name_GLAccount', GLAccount.Name);

            LibraryReportDataset.AssertCurrentRowValueEquals('UserID_GLEntry', GLEntry."User ID");
            LibraryReportDataset.AssertCurrentRowValueEquals('SourceCode_GLEntry', GLEntry."Source Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('SystemExclCreatedEntry', GLEntry."System-Created Entry");
            LibraryReportDataset.AssertCurrentRowValueEquals('PriorExclYearEntry', GLEntry."Prior-Year Entry");
        until GLEntry.Next() = 0;

        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.SetRange("Bal. Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Posting Info",
          'No_GLAccount', 'Name_GLAccount', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet Posting Info",
          'No_GLAccount', 'Name_GLAccount', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');
    end;

    local procedure VerifyVATInfoReportData(GLAccount: Record "G/L Account")
    var
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.CalcFields(Balance);
        LibraryReportDataset.LoadDataSetFile();
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('GLAccountNo', GLAccount."No.");
            LibraryReportDataset.SetRange('DocumentNo_GLEntry', GLEntry."Document No.");
            LibraryReportDataset.GetNextRow();
            Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one entry per GL entry in the report.');
            LibraryReportDataset.AssertCurrentRowValueEquals('BalAccountNo_GLEntry', GLEntry."Bal. Account No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_GLEntry', GLEntry.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('GlBalance', GLAccount.Balance);
            LibraryReportDataset.AssertCurrentRowValueEquals('GLAccountName', GLAccount.Name);

            LibraryReportDataset.AssertCurrentRowValueEquals('VATBusPostingGroup_GLEntry', GLEntry."VAT Bus. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATProdPostingGroup_GLEntry', GLEntry."VAT Prod. Posting Group");
            VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATPercent', VATPostingSetup."VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount_GLEntry', GLEntry."VAT Amount");
        until GLEntry.Next() = 0;

        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.SetRange("Bal. Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet VAT Info",
          'GLAccountNo', 'GLAccountName', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccount."No.");
        VerifyGenJnlLinesInReportData(GenJournalLine, GLAccount, REPORT::"SR G/L Acc Sheet VAT Info",
          'GLAccountNo', 'GLAccountName', 'DocumentNo_GenJournalLine', 'Description_GenJournalLine', 'JournalBatchName_GenJournalLine');
    end;

    local procedure VerifyGenJnlLinesInReportData(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account"; ReportID: Integer; GLAccountNoTag: Text; GLAccountNameTag: Text; DocNoTag: Text; DescTag: Text; JnlBatchNameTag: Text)
    begin
        if GenJournalLine.FindSet() then
            repeat
                LibraryReportDataset.Reset();
                LibraryReportDataset.SetRange(GLAccountNoTag, GLAccount."No.");
                LibraryReportDataset.SetRange(DocNoTag, GenJournalLine."Document No.");
                LibraryReportDataset.SetRange(DescTag, GenJournalLine.Description);
                LibraryReportDataset.GetNextRow();
                Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be one entry per GL line in the report.');
                LibraryReportDataset.AssertCurrentRowValueEquals(JnlBatchNameTag, GenJournalLine."Journal Batch Name");
                LibraryReportDataset.AssertCurrentRowValueEquals(GLAccountNameTag, GLAccount.Name);
                VerifySpecificTags(GenJournalLine, ReportID, GenJournalLine."Bal. Account No." = GLAccount."No.")
            until GenJournalLine.Next() = 0;
    end;

    local procedure VerifySpecificTags(GenJournalLine: Record "Gen. Journal Line"; ReportID: Integer; GlAccIsBalAcc: Boolean)
    begin
        case ReportID of
            REPORT::"SR G/L Acc Sheet Bal Account":
                if GlAccIsBalAcc then begin
                    LibraryReportDataset.AssertCurrentRowValueEquals('ProvCredit', GenJournalLine."Debit Amount");
                    LibraryReportDataset.AssertCurrentRowValueEquals('ProvDebit', GenJournalLine."Credit Amount");
                end else begin
                    LibraryReportDataset.AssertCurrentRowValueEquals('ProvDebit', GenJournalLine."Debit Amount");
                    LibraryReportDataset.AssertCurrentRowValueEquals('ProvCredit', GenJournalLine."Credit Amount");
                end;
            REPORT::"SR G/L Acc Sheet Foreign Curr":
                if GenJournalLine."Currency Code" <> '' then
                    LibraryReportDataset.AssertCurrentRowValueEquals('GenJournalLineFcyAcyAmt', Abs(GenJournalLine.Amount))
                else
                    LibraryReportDataset.AssertCurrentRowValueEquals('GenJournalLineFcyAcyAmt', 0);
            REPORT::"SR G/L Acc Sheet VAT Info":
                if GlAccIsBalAcc then begin // TFS 406567
                    LibraryReportDataset.AssertCurrentRowValueEquals('VAT_GenJournalLine', GenJournalLine."VAT %");
                    LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount_GenJournalLine', GenJournalLine."VAT Amount");
                    LibraryReportDataset.AssertCurrentRowValueEquals(
                        'VATBusPostingGroup_GenJournalLine', GenJournalLine."VAT Bus. Posting Group");
                    LibraryReportDataset.AssertCurrentRowValueEquals(
                        'VATProdPostingGroup_GenJournalLine', GenJournalLine."VAT Prod. Posting Group");
                end else begin
                    LibraryReportDataset.AssertCurrentRowValueEquals('VAT_GenJournalLine', GenJournalLine."Bal. VAT %");
                    LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount_GenJournalLine', GenJournalLine."Bal. VAT Amount");
                    LibraryReportDataset.AssertCurrentRowValueEquals(
                        'VATBusPostingGroup_GenJournalLine', GenJournalLine."Bal. VAT Bus. Posting Group");
                    LibraryReportDataset.AssertCurrentRowValueEquals(
                        'VATProdPostingGroup_GenJournalLine', GenJournalLine."Bal. VAT Prod. Posting Group");
                end;
        end;
    end;

    local procedure VerifyDebitCreditForTemporaryPostings(GenJournalLine: array[3] of Record "Gen. Journal Line"; DebitTag: Text; CreditTag: Text)
    begin
        // [THEN] Temporary posting for "G1" has "Credit Amount" = 0 and "Debit Amount" = "G1".Amount
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow(DebitTag, GenJournalLine[1].Amount) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals(CreditTag, 0);
        LibraryReportDataset.AssertCurrentRowValueEquals(DebitTag, GenJournalLine[1].Amount);

        // [THEN] Temporary posting for "G2" has "Credit Amount" = -"G2".Amount and "Debit Amount" = 0
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow(CreditTag, -GenJournalLine[2].Amount) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals(CreditTag, -GenJournalLine[2].Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals(DebitTag, 0);

        // [THEN] Temporary posting for "G3" has "Credit Amount" = 0 and "Debit Amount" = "G3".Amount
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow(DebitTag, GenJournalLine[3].Amount) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals(CreditTag, 0);
        LibraryReportDataset.AssertCurrentRowValueEquals(DebitTag, GenJournalLine[3].Amount);
    end;

    local procedure CreateCustomer(
        var CustomerPostingGroup: Record "Customer Posting Group";
        var Customer: Record Customer;
        CurrencyCode: Code[20])
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplateType::General);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount.Modify(true);
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSheetBalanceInfoReqPageHandler(var SRGLAccSheetBalAccount: TestRequestPage "SR G/L Acc Sheet Bal Account")
    begin
        SRGLAccSheetBalAccount.NewPagePerAcc.SetValue(true); // New page per account.
        SRGLAccSheetBalAccount.ShowAllAccounts.SetValue(false); // Show account without balance.
        SRGLAccSheetBalAccount.WithoutClosingEntries.SetValue(false); // Without closing entries.
        SRGLAccSheetBalAccount.JourName1.Lookup(); // lookup the provisional journal(s).
        SRGLAccSheetBalAccount.JourName2.Lookup();
        SRGLAccSheetBalAccount.JourName3.Lookup();
        SRGLAccSheetBalAccount.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSheetFCYReqPageHandler(var SRGLAccSheetForeignCurr: TestRequestPage "SR G/L Acc Sheet Foreign Curr")
    begin
        SRGLAccSheetForeignCurr.NewPagePerAcc.SetValue(true); // New page per account.
        SRGLAccSheetForeignCurr.ShowAllAccounts.SetValue(false); // Show account without balance.
        SRGLAccSheetForeignCurr.WithoutClosingEntries.SetValue(false); // Without closing entries.
        SRGLAccSheetForeignCurr.JourName1.Lookup(); // lookup the provisional journal(s).
        SRGLAccSheetForeignCurr.JourName2.Lookup();
        SRGLAccSheetForeignCurr.JourName3.Lookup();
        SRGLAccSheetForeignCurr.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSheetACYReqPageHandler(var SRGLAccSheetReportigCur: TestRequestPage "SR G/L Acc Sheet Reportig Cur")
    begin
        SRGLAccSheetReportigCur.NewPagePerAcc.SetValue(true); // New page per account.
        SRGLAccSheetReportigCur.ShowAllAccounts.SetValue(false); // Show account without balance.
        SRGLAccSheetReportigCur.WithoutClosingEntries.SetValue(false); // Without closing entries.
        SRGLAccSheetReportigCur.JourName1.Lookup(); // lookup the provisional journal(s).
        SRGLAccSheetReportigCur.JourName2.Lookup();
        SRGLAccSheetReportigCur.JourName3.Lookup();
        SRGLAccSheetReportigCur.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSheetPostingInfoReqPageHandler(var SRGLAccSheetPostingInfo: TestRequestPage "SR G/L Acc Sheet Posting Info")
    begin
        SRGLAccSheetPostingInfo.NewPagePerAcc.SetValue(true); // New page per account.
        SRGLAccSheetPostingInfo.ShowAllAccounts.SetValue(false); // Show account without balance.
        SRGLAccSheetPostingInfo.WithoutClosingEntries.SetValue(false); // Without closing entries.
        SRGLAccSheetPostingInfo.JourName1.Lookup(); // lookup the provisional journal(s).
        SRGLAccSheetPostingInfo.JourName2.Lookup();
        SRGLAccSheetPostingInfo.JourName3.Lookup();
        SRGLAccSheetPostingInfo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSheetVATInfoReqPageHandler(var SRGLAccSheetVATInfo: TestRequestPage "SR G/L Acc Sheet VAT Info")
    begin
        SRGLAccSheetVATInfo.NewPagePerAcc.SetValue(true); // New page per account.
        SRGLAccSheetVATInfo.ShowAllAccounts.SetValue(false); // Show account without balance.
        SRGLAccSheetVATInfo.WithoutClosingEntries.SetValue(false); // Without closing entries.
        SRGLAccSheetVATInfo.JourName1.Lookup(); // lookup the provisional journal(s).
        SRGLAccSheetVATInfo.JourName2.Lookup();
        SRGLAccSheetVATInfo.JourName3.Lookup();
        SRGLAccSheetVATInfo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSheetVATInfoWithoutLookupJournalsRPH(var SRGLAccSheetVATInfo: TestRequestPage "SR G/L Acc Sheet VAT Info")
    begin
        SRGLAccSheetVATInfo.NewPagePerAcc.SetValue(true);
        SRGLAccSheetVATInfo.ShowAllAccounts.SetValue(false);
        SRGLAccSheetVATInfo.WithoutClosingEntries.SetValue(false);
        SRGLAccSheetVATInfo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSheetForeignCurrReqPageHandler(var SRGLAccSheetForeignCurr: TestRequestPage "SR G/L Acc Sheet Foreign Curr")
    var
        GLAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(GLAccountNo);
        SRGLAccSheetForeignCurr."G/L Account".SetFilter("No.", GLAccountNo);
        SRGLAccSheetForeignCurr.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalBatchesPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.First();
        GeneralJournalBatches.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}