codeunit 134453 "ERM Fixed Assets GL Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        UnknownErr: Label 'Unknown error.';
        AllowPostingToMainAssetsMsg: Label '%1 %2 = %3 is a %4. %5 must be %6 in %7.', Comment = '.';
        DisposalMustNotBePositiveMsg: Label 'Disposal must not be positive on %1 for %2 %3 = %4 in %5 = %6.', Comment = '.';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '.';
        ReverseErr: Label 'You can only reverse entries that were posted from a journal.';
        EndingDateErr: Label 'You must specify an Ending Date that is later than the Starting Date.';
        GLBudgetEntriesMustExistMsg: Label 'G/L Budget Entries must exist.';
        GLBudgetEntriesMustNotExistMsg: Label 'G/L Budget Entries must not exist.';
        WrongAmountErr: Label 'Wrong amount.';
        PeriodTxt: Label '12';
        OnlyOneDefaultDeprBookErr: Label 'Default FA Depreciation Book Only one fixed asset depreciation book can be marked as the default book';
        CompletionStatsTok: Label 'The depreciation has been calculated.';

    [Test]
    [HandlerFunctions('GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure HideAllowPaymentExportForNonPaymentBatches()
    var
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        Initialize();

        // Setup
        FixedAssetGLJournal.OpenEdit();

        // Exercise
        LibraryLowerPermissions.SetO365Basic();
        LibraryVariableStorage.Enqueue(false);
        FixedAssetGLJournal.CurrentJnlBatchName.Lookup();

        // Verify
        // ModalPageHandler verifies the visibility status of Allow Payment Export
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShowAllowPaymentExportForPaymentBatches()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        Initialize();

        // Setup
        PaymentJournal.OpenEdit();

        // Exercise
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.AddBanking();
        LibraryVariableStorage.Enqueue(true);
        PaymentJournal.CurrentJnlBatchName.Lookup();

        // Verify
        // ModalPageHandler verifies the visibility status of Allow Payment Export
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalWithDuplicateBookCode()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        // Test Duplicate Entry in FA Journal Line after Posting FA G/L Journal with Duplicate in Depreciation Book Code.

        // 1. Setup: Create Depreciation Book with Default Exchange Rate, Fixed Asset, FA Depreciation Book with Default Depreciation
        // Book on FA Setup and Created new Depreciation Book.
        Initialize();
        CreateJournalSetupDepreciation(DepreciationBook);
        UpdateDepreciationBook(DepreciationBook);
        CreateFAWithFADepreciationBook(FADepreciationBook, DepreciationBook.Code);
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Create and Post General Journal Line with Duplicate in Depreciation Book Code.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        CreateGeneralJournal(GenJournalLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GLAccount);
        GenJournalLine.Validate("Duplicate in Depreciation Book", DepreciationBook.Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Duplicate Entry in FA Journal Line.
        VerifyFAJournalLine(
          FADepreciationBook."FA No.", DepreciationBook.Code,
          Round(GenJournalLine.Amount * 100 / DepreciationBook."Default Exchange Rate"));

        // 4. Teardown: Update Part of Duplication List as False on created Depreciation Book.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePartOfDuplicationList(DepreciationBook, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalWithUseDuplicateList()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        // Test Duplicate Entry in FA Journal Line after Posting FA G/L Journal with Use Duplication List as True.

        // 1. Setup: Create Depreciation Book with Default Exchange Rate, Fixed Asset, FA Depreciation Book with Default Depreciation
        // Book on FA Setup and Created new Depreciation Book.
        Initialize();
        CreateJournalSetupDepreciation(DepreciationBook);
        UpdateDepreciationBook(DepreciationBook);
        CreateFAWithFADepreciationBook(FADepreciationBook, DepreciationBook.Code);
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Create and Post General Journal Line with Use Duplication List as True.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateGeneralJournal(GenJournalLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GLAccount);
        GenJournalLine.Validate("Use Duplication List", true);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Duplicate Entry in FA Journal Line.
        VerifyFAJournalLine(
          FADepreciationBook."FA No.", DepreciationBook.Code,
          Round(GenJournalLine.Amount * 100 / DepreciationBook."Default Exchange Rate"));

        // 4. Teardown: Update Part of Duplication List as False on created Depreciation Book.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePartOfDuplicationList(DepreciationBook, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalWithOutExchangeRate()
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalLine: Record "Gen. Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        // Test Duplicate Entry in FA Journal Line after Posting FA G/L Journal with Use Duplication List as True and Depreciation
        // Book without Default Exchange Rate.

        // 1. Setup: Create Depreciation Book with Part of Duplication List as True, Fixed Asset, FA Depreciation Book with Default
        // Depreciation Book on FA Setup and Created new Depreciation Book.
        Initialize();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        UpdatePartOfDuplicationList(DepreciationBook, true);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
        CreateFAWithFADepreciationBook(FADepreciationBook, DepreciationBook.Code);
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Create and Post General Journal Line with Use Duplication List as True.
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        CreateGeneralJournal(GenJournalLine, FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", GLAccount);
        GenJournalLine.Validate("Use Duplication List", true);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Duplicate Entry in FA Journal Line.
        VerifyFAJournalLine(FADepreciationBook."FA No.", DepreciationBook.Code, GenJournalLine.Amount);

        // 4. Teardown: Update Part of Duplication List as False on created Depreciation Book.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePartOfDuplicationList(DepreciationBook, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExchangeRateOnDepreciationBook()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        // Test Default Exchange Rate on Depreciation Book after update Use FA Exch. Rate in Duplic. as False.

        // 1. Setup: Create Depreciation Book with Default Exchange Rate.
        Initialize();
        CreateJournalSetupDepreciation(DepreciationBook);

        // 2. Exercise: Update Use FA Exch. Rate in Duplic. as False on Depreciation Book.
        LibraryLowerPermissions.SetO365FASetup();
        DepreciationBook.Validate("Use FA Exch. Rate in Duplic.", false);
        DepreciationBook.Modify(true);

        // 3. Verify: Verify Default Exchange Rate on Depreciation Book.
        DepreciationBook.TestField("Default Exchange Rate", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AcquisitionCostIntegrationTrue()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        DepreciationBook: Record "Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        // Test the Posting of fixed Assets in FA G/L Journal.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and Put check marks on Integration Tab.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        SetupGLIntegrationInBook(DepreciationBook, true);
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Create and post a line in FA G/L Journal with FA Posting Type Acquisition Cost.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2), GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        VerifyAmountInFALedgerEntry(FALedgerEntry, FADepreciationBook."FA No.", GenJournalLine.Amount);
        VerifyAmountInGLEntry(FixedAsset."No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DepreciationIntegrationTrue()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        FANo: Code[20];
    begin
        // Post a line in FA G/L journals with FA Posting Type Depreciation.
        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and Put check marks on Integration Tab.
        Initialize();
        FANo := CreateFixedAssetWithIntegration(GenJournalLine."FA Posting Type"::Depreciation, -1, GenJournalLine);

        // 2. Exercise: Create and post a line in FA G/L Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        VerifyAmountInFALedgerEntry(FALedgerEntry, FANo, GenJournalLine.Amount);
        VerifyAmountInGLEntry(FANo, GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteDownIntegrationTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
    begin
        // Post a line in FA G/L journals with FA Posting Type Write-Down.
        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and Put check marks on Integration Tab.
        Initialize();
        FANo := CreateFixedAssetWithIntegration(GenJournalLine."FA Posting Type"::"Write-Down", -1, GenJournalLine);

        // 2. Exercise: Create and post a line in FA G/L Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Write-Down");
        VerifyAmountInFALedgerEntry(FALedgerEntry, FANo, GenJournalLine.Amount);
        VerifyAmountInGLEntry(FANo, GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppreciationIntegrationTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
    begin
        // Post a line in FA G/L journals with FA Posting Type Appreciation.
        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and Put check marks on Integration Tab.
        Initialize();
        FANo := CreateFixedAssetWithIntegration(GenJournalLine."FA Posting Type"::Appreciation, 1, GenJournalLine);

        // 2. Exercise: Create and post a line in FA G/L Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Appreciation);
        VerifyAmountInFALedgerEntry(FALedgerEntry, FANo, GenJournalLine.Amount);
        VerifyAmountInGLEntry(FANo, GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom1IntegrationTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
    begin
        // Post a line in FA G/L journals with FA Posting Type Custom 1.
        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and Put check marks on Integration Tab.
        Initialize();
        FANo := CreateFixedAssetWithIntegration(GenJournalLine."FA Posting Type"::"Custom 1", -1, GenJournalLine);

        // 2. Exercise: Create and post a line in FA G/L Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Custom 1");
        VerifyAmountInFALedgerEntry(FALedgerEntry, FANo, GenJournalLine.Amount);
        VerifyAmountInGLEntry(FANo, GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Custom2IntegrationTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
    begin
        // Post a line in FA G/L journals with FA Posting Type Custom 2.
        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and Put check marks on Integration Tab.
        Initialize();
        FANo := CreateFixedAssetWithIntegration(GenJournalLine."FA Posting Type"::"Custom 2", -1, GenJournalLine);

        // 2. Exercise: Create and post a line in FA G/L Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Custom 2");
        VerifyAmountInFALedgerEntry(FALedgerEntry, FANo, GenJournalLine.Amount);
        VerifyAmountInGLEntry(FANo, GenJournalLine.Amount);
    end;

    local procedure CreateFixedAssetWithIntegration(GenJnlLineFAPostingType: Enum "Gen. Journal Line FA Posting Type"; AmountSign: Integer; var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        DepreciationBook: Record "Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGenJournalBatch(GenJournalBatch);
        SetupGLIntegrationInBook(DepreciationBook, true);

        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2), GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJnlLineFAPostingType, Round(GenJournalLine.Amount / 4) * AmountSign,
          GLAccount);
        exit(FixedAsset."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceIntegrationTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Maintenance: Record Maintenance;
        FANo: Code[20];
    begin
        // Test the Posting of fixed Assets in FA G/L Journal.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and Put check marks on Integration Tab.
        Initialize();
        FANo := CreateFixedAssetWithIntegration(GenJournalLine."FA Posting Type"::Maintenance, -1, GenJournalLine);
        MaintenanceCodeGenJournalLine(GenJournalLine, Maintenance);

        // 2. Exercise: To create and post a line in FA G/L Journal with FA Posting Type Maintenance.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        VerifyMaintenanceLedgerEntry(FANo, GenJournalLine.Amount);
        VerifyMaintenanceInGLEntry(FANo, GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetedAssetWithError()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        FASetup: Record "FA Setup";
        Maintenance: Record Maintenance;
        GLAccount: Record "G/L Account";
    begin
        // Test the Posting of fixed Assets in FA G/L Journal.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and put check marks on Maintenance,
        // Acquisition Cost, Disposal fields on Integration Tab.
        Initialize();
        CreateBudgtedFixedAsset(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset2."No.", FixedAsset2."FA Posting Group", DepreciationBook.Code);

        CreateGenJournalBatch(GenJournalBatch);
        SetupPartialGLIntegrationBook(DepreciationBook, true);
        SetupAllowPostingToMainAssets(false);
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Create and post a line in FA G/L Journal with FA Posting Type Maintenance.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateJnlLineWithBudgetedAsset(GenJournalLine, FADepreciationBook, GenJournalBatch, FixedAsset."No.", Maintenance, GLAccount);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify the Error that Allow Posting to Main Assets must be Yes in FA Setup.
        Assert.AreEqual(
          StrSubstNo(
            AllowPostingToMainAssetsMsg, FixedAsset.TableCaption(), FixedAsset.FieldCaption("No."), FixedAsset."No.",
            FixedAsset."Main Asset/Component", FASetup.FieldCaption("Allow Posting to Main Assets"), true, FASetup.TableCaption()),
          GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BudgetedAssetWithoutError()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        Maintenance: Record Maintenance;
        GLAccount: Record "G/L Account";
    begin
        // Test the Posting of fixed Assets in FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and put check marks on Maintenance,
        // Acquisition Cost, Disposal fields on Integration Tab.
        Initialize();
        CreateBudgtedFixedAsset(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2."No.", FixedAsset2."FA Posting Group", DepreciationBook.Code);

        CreateGenJournalBatch(GenJournalBatch);
        SetupPartialGLIntegrationBook(DepreciationBook, true);
        SetupAllowPostingToMainAssets(true);
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        LibraryERM.CreateGLAccount(GLAccount);

        // 2. Exercise: Create and post a line in FA G/L Journal with FA Posting Type Maintenance.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateJnlLineWithBudgetedAsset(GenJournalLine, FADepreciationBook2, GenJournalBatch, FixedAsset."No.", Maintenance, GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in Maintenance Ledger Entry correctly.
        VerifyMaintenanceLedgerEntry(FixedAsset."No.", -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetAcquisitionCost()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DepreciationBook: Record "Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        // Test the Posting of fixed Assets in FA G/L Journal.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and put check marks on Maintenance,
        // Acquisition Cost, Disposal fields on Integration Tab.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        SetupPartialGLIntegrationBook(DepreciationBook, true);

        // 2. Exercise: Create and post a line in FA G/L Journal with FA Posting Type Acquisition Cost.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2), GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        VerifyAmountInFALedgerEntry(FALedgerEntry, FADepreciationBook."FA No.", GenJournalLine.Amount);
        VerifyAmountInGLEntry(FixedAsset."No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetDisposalWithError()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        // Test the Posting of fixed Assets in FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and put check mark on Maintenance,
        // Acquisition Cost, Disposal fields on Integration Tab.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        SetupPartialGLIntegrationBook(DepreciationBook, true);

        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(1000, 2), GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Create and post a line in FA G/L Journal with FA Posting Type Disposal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Disposal,
          LibraryRandom.RandDec(1000, 2), GLAccount);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify that Disposal must not be positive for Depreciation Book.
        Assert.ExpectedError(
          StrSubstNo(
            DisposalMustNotBePositiveMsg, WorkDate(), FixedAsset.TableCaption(), FixedAsset.FieldCaption("No."), FixedAsset."No.",
            FADepreciationBook.FieldCaption("Depreciation Book Code"), FADepreciationBook."Depreciation Book Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetDisposalWithoutError()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        // Test the Posting of fixed Assets in FA G/L Journal.

        // 1.Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group and put check mark on Maintenance,
        // Acquisition Cost, Disposal fields on Integration Tab.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        SetupPartialGLIntegrationBook(DepreciationBook, true);

        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(1000, 2), GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Create and post a line in FA G/L Journal with FA Posting Type Disposal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Disposal, -GenJournalLine.Amount,
          GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify that the Amount is Posted in FA Ledger Entry and G/L Entry correctly.
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
        VerifyAmountInFALedgerEntry(FALedgerEntry, FixedAsset."No.", GenJournalLine.Amount);
        VerifyAmountInGLEntry(FixedAsset."No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAJournalWithSalvageValue()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        Amount: Decimal;
    begin
        // Check FA Ledger Entry after Posting Salvage Value with Posting of Acquisition Cost.

        // 1.Setup: Create Fixed Asset with Depreciation Book Declining Balance %.
        Initialize();
        CreateFAWithDecliningBalanceFADeprBook(FADepreciationBook);

        // 2.Exercise: Create and post journal lines
        LibraryLowerPermissions.SetO365FAEdit();
        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostFAJournalLine(FADepreciationBook, Amount, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateAndPostFAJournalLine(FADepreciationBook, -Amount / 2, FAJournalLine."FA Posting Type"::"Salvage Value");

        // 3.Verify: Verify FA Ledger Entry with Salvage Value and Acquisition Cost.
        VerifyFALedgerEntry(FALedgerEntry."FA Posting Type"::"Salvage Value", FADepreciationBook."FA No.", -Amount / 2);
        VerifyFALedgerEntry(FALedgerEntry."FA Posting Type"::"Acquisition Cost", FADepreciationBook."FA No.", Amount);
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAJournalWithCalcDepreciation()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FAAmount: Decimal;
        Amount: Decimal;
        NoOfMonth: Integer;
    begin
        // Check FA journal Line after Calculating Depreciation.
        // Create Fixed Asset with Depreciation Book Declining Balance %.
        Initialize();
        CreateFAWithDecliningBalanceFADeprBook(FADepreciationBook);
        FAAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostFAJournalLine(FADepreciationBook, FAAmount, FAJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateAndPostFAJournalLine(FADepreciationBook, -FAAmount / 2, FAJournalLine."FA Posting Type"::"Salvage Value");
        CreateFAJournalSetup(FADepreciationBook."Depreciation Book Code");

        // Exercise: Calculate Depreciation. Required 12 for dividing Depreciation Value with Random Values.
        LibraryLowerPermissions.SetO365FAEdit();
        Amount := FAAmount / 2;
        NoOfMonth := LibraryRandom.RandInt(10);
        RunCalculateDepeciation(FADepreciationBook, FADepreciationBook."FA No.", NoOfMonth);
        Amount := Round((Amount * FADepreciationBook."Declining-Balance %" / 100) * NoOfMonth / 12);

        // Verify: Verify FA Journal Line with Calculated Depreciation Amount.
        GeneralLedgerSetup.Get();
        FAJournalLine.SetRange("FA No.", FADepreciationBook."FA No.");
        FAJournalLine.FindFirst();
        Assert.AreNearlyEqual(
          -Amount, FAJournalLine.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, FAJournalLine.FieldCaption(Amount), -Amount, FAJournalLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('Internal')]
    procedure FAJournalWithCalcDepreciationBlankDocNoTwoFA()
    var
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook1: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Calculate Depreciation]
        // [SCENARIO 352564] Run Calculate Depreciation for two fixed assets with blank Document No
        Initialize();

        // [GIVEN] Fixed assets "FA1","FA2" with aquisition cost
        CreateFAWithAcquisitionCost(FADepreciationBook1);
        CreateFAWithAcquisitionCost(FADepreciationBook2);

        // [GIVEN] FA Journal Line has Document No "DeprDoc" after running Calculate Depreciation report for "FA1"
        RunCalculateDepeciation(FADepreciationBook1, '', LibraryRandom.RandInt(10));
        FAJournalLine.SetRange("FA No.", FADepreciationBook1."FA No.");
        FAJournalLine.FindFirst();
        DocumentNo := FAJournalLine."Document No.";

        // [WHEN]  Run Calculate Depreciation report for "FA2"
        RunCalculateDepeciation(FADepreciationBook2, '', LibraryRandom.RandInt(10));

        // [THEN] FA Journal Line has Document No "DeprDoc" in the same journal for "FA2"
        FAJournalLine.SetRange("Journal Template Name", FAJournalLine."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalLine."Journal Batch Name");
        FAJournalLine.SetRange("FA No.", FADepreciationBook2."FA No.");
        FAJournalLine.FindFirst();
        FAJournalLine.TestField("Document No.", DocumentNo);
    end;

    local procedure CreateFAWithDecliningBalanceFADeprBook(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        // Setup: Create Fixed Asset and Depreciation Book with Random Declining Balance %.
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Allow more than 360/365 Days", true);
        DepreciationBook.Modify(true);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        FADepreciationBook.Validate("Declining-Balance %", LibraryRandom.RandDec(10, 2));
        FADepreciationBook.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseErrorOnFALedgerEntry()
    var
        SalesLine: Record "Sales Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        // Check Reverse Transaction Error on FA Ledger Entry after Posting FA with Sales Invoice.

        // Setup: Create FA and Post Fa Journal Line with Acquisition Cost then Post Sales Invoice.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", CreateDepreciationBook());
        CreateAndPostFAJournalLine(
          FADepreciationBook, LibraryRandom.RandDec(100, 2), FAJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateAndPostSalesInvoice(SalesLine, FADepreciationBook);

        // Exercise: Try Reverse Transaction on Posted FA Entry which is posted through Sales Invoice.
        LibraryLowerPermissions.SetO365FAView();
        FALedgerEntries.OpenView();
        FALedgerEntries.FILTER.SetFilter("FA No.", FixedAsset."No.");
        FALedgerEntries.FILTER.SetFilter("FA Posting Category", Format(FALedgerEntry."FA Posting Category"::Disposal));
        asserterror FALedgerEntries.ReverseTransaction.Invoke();

        // Verify: Verify Error raised on FA Ledger entry during Reverse Transaction.
        Assert.ExpectedError(StrSubstNo(ReverseErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFAEntriesToGLBudgetError()
    begin
        // Test that System generates an error when Starting Date is later than the Ending Date on Report Copy FA Entries To G/L Budget.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Copy FA Entries To G/L Budget with Random Starting Date.
        LibraryLowerPermissions.SetO365Basic();
        asserterror RunCopyFAEntriesToGLBudget('', '', '', CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // 3. Verify: Verify that System generates an error when Starting Date is later than the Ending Date.
        Assert.AreEqual(StrSubstNo(EndingDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFAEntriesToGLBudgetActive()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLBudgetName: Record "G/L Budget Name";
        DepreciationBook: Code[10];
    begin
        // Test and verify Copy FA Entries To G/L Budget Report functionality for Active Fixed Asset..

        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group. Create and post General Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        CreateAndPostFAJournalLines(FADepreciationBook);
        LibraryFixedAsset.CreateGLBudgetName(GLBudgetName);
        Commit();  // COMMIT required for Batch Report.
        DepreciationBook := LibraryFixedAsset.GetDefaultDeprBook();

        // 2. Exercise: Run Copy FA Entries To G/L Budget.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddFinancialReporting();
        LibraryLowerPermissions.AddJournalsPost();
        RunCopyFAEntriesToGLBudget(FixedAsset."No.", DepreciationBook, GLBudgetName.Name, WorkDate());

        // 3. Verify: Verify FA Entries must be copy to G\L Budget Entries for Active Fixed Asset.
        // Using 6 because we have created 6 General Journal Lines with different FA Posting Type.
        Assert.AreEqual(6, GetNumberOfGLBudgetEntries(GLBudgetName.Name), GLBudgetEntriesMustExistMsg);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFAEntriesGLBudgetInactive()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Test and verify Copy FA Entries To G/L Budget Report functionality for Inactive Fixed Asset.

        // 1. Setup: Create Fixed Asset, FA Depreciation Book with FA Posting Group. Create and post General Journal Lines.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
        CreateAndPostFAJournalLines(FADepreciationBook);
        FixedAsset.Validate(Inactive, true);
        FixedAsset.Modify(true);
        LibraryFixedAsset.CreateGLBudgetName(GLBudgetName);
        Commit();  // COMMIT required for Batch Report.

        // 2. Exercise: Run Copy FA Entries To G/L Budget.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddFinancialReporting();
        LibraryLowerPermissions.AddJournalsPost();
        RunCopyFAEntriesToGLBudget(FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook(), GLBudgetName.Name, WorkDate());

        // 3. Verify: Verify FA Entries must not be copy to G\L Budget Entries for Inactive Fixed Asset.
        Assert.AreEqual(0, GetNumberOfGLBudgetEntries(GLBudgetName.Name), GLBudgetEntriesMustNotExistMsg);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesAfterReclassification()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        DocumentNo: Code[20];
        PostingDate: Date;
        AcquisitionCostBeforeReclassification: Decimal;
        DepreciationBeforeReclassification: Decimal;
        AcquisitionCostAfterReclassification: Decimal;
        DepreciationAfterReclassification: Decimal;
        ReclassifyAcqCostPct: Decimal;
        NumberOfDays: Integer;
    begin
        // NOTE: Test fails on WORKDATE = 1,2 January
        // Check GL Entries after posting FA Reclass Journals.

        // 1. Setup: Create and modify Depreciation Book, create FA Posting Group, create two Fixed Assets.
        Initialize();
        LibraryFiscalYear.CreateFiscalYear();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        ModifyDepreciationBookAndGenJournalBatch(DepreciationBook);
        CreateAndModifyFADepreciationBook(
          FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group", LibraryRandom.RandIntInRange(10, 20));  // Take Random value for Declining-Balance %.
        LibraryFixedAsset.CreateFixedAsset(FixedAsset2);
        FixedAsset2.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FixedAsset2.Modify(true);
        CreateAndModifyFADepreciationBook(
          FADepreciationBook2, FixedAsset2."No.", DepreciationBook.Code, FixedAsset2."FA Posting Group",
          FADepreciationBook."Declining-Balance %");

        // Create and post FA G/L Journal for Acquisition and Depriciation with Random Amounts.
        PostingDate := CalcDate('<12M - 2D>', WorkDate());  // Take Posting Date as per test.
        CreateGenJournalBatch(GenJournalBatch);
        SetupGLIntegrationInBook(DepreciationBook, true);
        CreateAndModifyFAGLJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandIntInRange(10000, 20000), PostingDate);
        AcquisitionCostBeforeReclassification := GenJournalLine.Amount;
        CreateAndModifyFAGLJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Depreciation,
          -LibraryRandom.RandIntInRange(1000, 2000), PostingDate);
        DepreciationBeforeReclassification := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Calculate Depreciation and post FA GL Lines created.
        DocumentNo := RunCalculateDepeciationWithBalAccount(FADepreciationBook, 12);  // Calculate Depreciation after one year.
        FindAndPostGenJournalLines(DocumentNo);
        ReclassifyAcqCostPct := LibraryRandom.RandIntInRange(10, 20);  // Take Random value for Reclassify Acq Cost %.

        AcquisitionCostAfterReclassification := Round(AcquisitionCostBeforeReclassification * ReclassifyAcqCostPct / 100);
        NumberOfDays :=
          DepreciationCalculation.DeprDays(
            DepreciationCalculation.ToMorrow(PostingDate, false, false), CalcDate('<1Y>', WorkDate()),
            false, false);
        DepreciationBeforeReclassification -=
          AcquisitionCostBeforeReclassification * (FADepreciationBook."Declining-Balance %" / 100) * (NumberOfDays / 360);
        DepreciationAfterReclassification := Round(DepreciationBeforeReclassification * ReclassifyAcqCostPct / 100);

        // 2. Exercise: Create and Post FA Raclass Journal.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        DocumentNo := CreateFAReclassJournalLine(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, ReclassifyAcqCostPct);
        FindAndPostGenJournalLines(DocumentNo);

        // 3. Verify: Verify GL Entries after Reclassification.
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        VerifyGLEntry(FixedAsset."No.", DocumentNo, FAPostingGroup."Acquisition Cost Account", -AcquisitionCostAfterReclassification);
        VerifyGLEntry(FixedAsset2."No.", DocumentNo, FAPostingGroup."Accum. Depreciation Account", DepreciationAfterReclassification);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcDepreciationAfterReversingFADepreciation()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Reverse] [Depreciation]
        // [SCENARIO 202489] Calculate depreciation after reversal
        Initialize();
        LibraryLowerPermissions.SetJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryLowerPermissions.AddO365FASetup();

        // [GIVEN] Fixed Asset with Acquisition Cost of 100
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        ModifyDepreciationBookAndGenJournalBatch(DepreciationBook);
        CreateAndModifyFADepreciationBook(
          FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group", LibraryRandom.RandIntInRange(10, 20));
        CreateGenJournalBatch(GenJournalBatch);
        SetupGLIntegrationInBook(DepreciationBook, true);
        CreateAndModifyFAGLJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandIntInRange(10000, 20000), WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Calculated depreciation with Amount = -10 on "DeprDate"
        FindAndPostGenJournalLines(
          RunCalculateDepeciationWithBalAccount(FADepreciationBook, 1));

        // [GIVEN] Reversed transaction of depreciation entry
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst();
        LibraryERM.ReverseTransaction(FALedgerEntry."Transaction No.");

        // [WHEN] Calculate Depreciation again on "DeprDate"
        DocumentNo := RunCalculateDepeciationWithBalAccount(FADepreciationBook, 1);

        // [THEN] Gen. Journal Line is created for Fixed Asset with Amount = -10 on "DeprDate"
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Document No.", DocumentNo);
        GenJournalLine.SetRange("Account No.", FixedAsset."No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", FALedgerEntry."Posting Date");
        GenJournalLine.TestField(Amount, FALedgerEntry.Amount);
        GenJournalLine.SetRange("Account No.");
        GenJournalLine.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DepriciationAfterReclassification()
    var
        DepreciationBook: Record "Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        DocumentNo: Code[20];
        PostingDate: Date;
        OriginalAcqCostAmount: Decimal;
        AcqCostReclassAmount: Decimal;
        OriginalDeprAmount: Decimal;
        DeprAmount: Decimal;
        DeprReclassAmount: Decimal;
        ReclassifyAcqCostPct: Decimal;
        ExpDeprAmount: Decimal;
        NumberOfDaysInPeriod: Decimal;
    begin
        // NOTE: Test fails on WORKDATE = 1,2 January
        // Check GL Entries when depreciation is calculated after Reclassification.

        // 1. Setup: Create Depreciation Book, create FA Posting Group, create two Fixed Assets.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        ModifyDepreciationBookAndGenJournalBatch(DepreciationBook);
        CreateAndModifyFADepreciationBook(
          FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group", LibraryRandom.RandIntInRange(10, 20));  // Take Random value for Declining-Balance %.
        LibraryFixedAsset.CreateFixedAsset(FixedAsset2);
        FixedAsset2.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FixedAsset2.Modify(true);
        CreateAndModifyFADepreciationBook(
          FADepreciationBook2, FixedAsset2."No.", DepreciationBook.Code, FixedAsset2."FA Posting Group",
          FADepreciationBook."Declining-Balance %");

        // Create and post FA G/L Journal for Acquisition and Depriciation with Random value.
        PostingDate := CalcDate('<12M - 2D>', WorkDate());  // Take Posting Date as per test.
        CreateGenJournalBatch(GenJournalBatch);
        SetupGLIntegrationInBook(DepreciationBook, true);
        CreateAndModifyFAGLJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandIntInRange(10000, 20000), PostingDate);
        OriginalAcqCostAmount := GenJournalLine.Amount;
        CreateAndModifyFAGLJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Depreciation,
          -LibraryRandom.RandIntInRange(1000, 2000), PostingDate);
        OriginalDeprAmount := GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Calculate Depreciation and post FA GL Lines created.
        DocumentNo := RunCalculateDepeciationWithBalAccount(FADepreciationBook, 12);  // Calculate Depreciation after one year.
        FindAndPostGenJournalLines(DocumentNo);
        ReclassifyAcqCostPct := LibraryRandom.RandIntInRange(10, 20);  // Take Random value for Reclassify Acq Cost %.
        AcqCostReclassAmount := OriginalAcqCostAmount * (1 - ReclassifyAcqCostPct / 100);
        NumberOfDaysInPeriod :=
          DepreciationCalculation.DeprDays(
            DepreciationCalculation.ToMorrow(PostingDate, false, false), CalcDate('<1Y>', WorkDate()),
            false, false);
        DeprAmount :=
          -Round(
            OriginalAcqCostAmount * (FADepreciationBook."Declining-Balance %" / 100) * (NumberOfDaysInPeriod / 360));  // Take 30 as No. of days for depreciation for one month.
        DeprReclassAmount := -Round((OriginalDeprAmount + DeprAmount) * ReclassifyAcqCostPct / 100);

        // Create and Post FA Raclass Journal.
        DocumentNo := CreateFAReclassJournalLine(FixedAsset."No.", FixedAsset2."No.", DepreciationBook.Code, ReclassifyAcqCostPct);
        FindAndPostGenJournalLines(DocumentNo);

        // 2. Exercise: Calculate Depreciation and post FA GL Lines created again.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        DocumentNo := RunCalculateDepeciationWithBalAccount(FADepreciationBook, 13);  // Calculate Depreciation after one year and one month.
        FindAndPostGenJournalLines(DocumentNo);

        // 3. Verify: Verify GL Entries after Depreciation.
        NumberOfDaysInPeriod := GetNumberOfDaysInPeriod(WorkDate(), CalcDate('<' + Format(13) + 'M>', WorkDate()));
        ExpDeprAmount :=
          -Round(
            (AcqCostReclassAmount + DeprReclassAmount) * (FADepreciationBook."Declining-Balance %" / 100) *
            (NumberOfDaysInPeriod / 360));

        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        VerifyGLEntry(FixedAsset."No.", DocumentNo, FAPostingGroup."Accum. Depreciation Account", ExpDeprAmount);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithDeprAcqCostAndSalvageValueFCY()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        GLAccount: Record "G/L Account";
        AcquisitionAmount: Decimal;
        DeprAmount: Decimal;
        SalvageValue: Decimal;
    begin
        // Verify that the system converts the Salvage Value into the Local Currency when Posting Gen. Journal Line
        // with Fixed Asset.
        Initialize();
        AcquisitionAmount := LibraryRandom.RandDec(1000, 2);
        DeprAmount := CreateFAWithAcqAndDepreciation(FADepreciationBook, AcquisitionAmount);
        LibraryERM.CreateGLAccount(GLAccount);

        // Excercise: Post Gen. Journal Line with Salvage Value in Foreign Currency.
        LibraryLowerPermissions.SetO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        SalvageValue := PostGenJnlLineWithDeprAcqCostAndSalvageValue(FADepreciationBook, CreateCurrencyWithExchRate(), GLAccount);

        // Verify: Salvage Value and Depreciation Amount.
        VerifyLastFALedgEntryAmount(FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::"Salvage Value", SalvageValue);
        VerifyLastFALedgEntryAmount(
          FADepreciationBook."FA No.", FALedgerEntry."FA Posting Type"::Depreciation,
          CalcAcqCostDepreciation(
            FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code", AcquisitionAmount, DeprAmount, SalvageValue));

        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertAmountForSourceCurrencyZeroAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Code[10];
    begin
        // Unit Test: verify that the function ConvertAmountToLCYForSourceCurrency returns the correct result
        // for Zero amount.
        // 1. Setup
        Initialize();
        Currency := CreateCurrencyWithExchRate();

        // 2. Exercise
        LibraryLowerPermissions.SetO365Basic();
        GenerateGenJnlLine(GenJournalLine, Currency);

        // 3. Verify
        Assert.AreEqual(0, GenJournalLine.ConvertAmtFCYToLCYForSourceCurrency(0), WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertAmountForSourceCurrencyLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Unit Test: verify that the function ConvertAmountToLCYForSourceCurrency returns the correct result
        // for Local Currency.
        Initialize();
        LibraryLowerPermissions.SetO365Basic();
        GenerateGenJnlLine(GenJournalLine, '');
        Amount := LibraryRandom.RandDec(10000, 2);
        Assert.AreEqual(Amount, GenJournalLine.ConvertAmtFCYToLCYForSourceCurrency(Amount), WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertAmountForSourceCurrencyFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Unit Test: verify that the function ConvertAmountToLCYForSourceCurrency returns the correct result
        // for Foreign Currency.
        // 1. Setup
        Initialize();
        CurrencyCode := CreateCurrencyWithExchRate();
        GenerateGenJnlLine(GenJournalLine, CurrencyCode);
        Amount := LibraryRandom.RandDec(10000, 2);

        // 2. Exercise and verify
        LibraryLowerPermissions.SetO365Basic();
        Assert.AreEqual(
          LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()),
          GenJournalLine.ConvertAmtFCYToLCYForSourceCurrency(Amount), WrongAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFAGenJnlLineWithDefaultDeprBookOnSetupUsingValueFromSetup()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);

        // Exercise
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        LibraryLowerPermissions.AddJournalsPost();
        FADepreciationBook.Validate("Default FA Depreciation Book", true);
        FADepreciationBook.Modify(true);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // Verify
        GenJournalLine.Find();
        GenJournalLine.TestField("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFAGenJnlLineWithoutDefaultDeprBookOnSetupUsingValueFromSetup()
    var
        CustomFADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SetupFADepreciationBook: Record "FA Depreciation Book";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(CustomFADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);

        // Exercise
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        FASetup.Get();
        CreateFADepreciationBook(SetupFADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", FASetup."Default Depr. Book");

        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // Verify
        GenJournalLine.Find();
        GenJournalLine.TestField("Depreciation Book Code", SetupFADepreciationBook."Depreciation Book Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateFAGenJnlLineWithoutDefaultDeprBookOnSetupUsingDefaultFADeprBook()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);

        FASetup.Get();
        FASetup.Validate("Default Depr. Book", '');
        FASetup.Modify(true);

        // Exercise
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryLowerPermissions.AddO365FAEdit();
        FADepreciationBook.Validate("Default FA Depreciation Book", true);
        FADepreciationBook.Modify(true);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));

        // Verify
        GenJournalLine.Find();
        GenJournalLine.TestField("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFixedAssetMultipleDefaultDeprBooksFails()
    var
        DefaultDepreciationBook: Record "Depreciation Book";
        DefaultFADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        Initialize();

        // Setup
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);

        CreateJournalSetupDepreciation(DefaultDepreciationBook);
        CreateFADepreciationBook(DefaultFADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DefaultDepreciationBook.Code);
        DefaultFADepreciationBook.Validate("Default FA Depreciation Book", true);
        DefaultFADepreciationBook.Modify(true);

        // Exercise
        LibraryLowerPermissions.SetO365FASetup();
        LibraryLowerPermissions.AddO365FAEdit();
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        asserterror FADepreciationBook.Validate("Default FA Depreciation Book", true);

        // Verify
        Assert.ExpectedError(OnlyOneDefaultDeprBookErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Fixed Assets GL Journal");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets GL Journal");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateFAPostingGroup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets GL Journal");
    end;

    local procedure CreateFAWithAcqAndDepreciation(var FADepreciationBook: Record "FA Depreciation Book"; AcquisitionAmount: Decimal): Decimal
    var
        FixedAsset: Record "Fixed Asset";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DepreciationBook: Record "Depreciation Book";
        GLAccount: Record "G/L Account";
        DeprAmount: Decimal;
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        CreateGenJournalBatch(GenJournalBatch);
        SetupGLIntegrationInBook(DepreciationBook, true);
        LibraryERM.CreateGLAccount(GLAccount);

        DeprAmount := -Round(AcquisitionAmount / 3);
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost", AcquisitionAmount,
          GLAccount);
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Depreciation, DeprAmount,
          GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        exit(DeprAmount);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; FADepreciationBook: Record "FA Depreciation Book")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        FindCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FADepreciationBook."FA No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateBudgtedFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("Budgeted Asset", true);
        FixedAsset.Validate("Main Asset/Component", FixedAsset."Main Asset/Component"::"Main Asset");
        FixedAsset.Modify(true);
    end;

    local procedure CreateDepreciationBook(): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFAJournalSetup(DepreciationBookCode: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        SelectFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBookCode, '');
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalBatch."Journal Template Name");
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatch.Name);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Depreciation Ending Date greater than Depreciation Starting Date, Using the Random Number for the Year.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateAndPostFAJournalLines(FADepreciationBook: Record "FA Depreciation Book")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Amount: Decimal;
    begin
        CreateGenJournalBatch(GenJournalBatch);
        Amount := LibraryRandom.RandDec(1000, 2) + 100;  // Use Random Amount because value is not important.
        LibraryERM.CreateGLAccount(GLAccount);
        // Create 6 General Journal Lines with different FA Posting Type.
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost", Amount, GLAccount);
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Depreciation, -Amount / 4, GLAccount);
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Write-Down", -Amount / 4, GLAccount);
        CreateGenJournalLine(GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Appreciation,
          Amount, GLAccount);
        CreateGenJournalLine(GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Custom 1",
          -Amount / 4, GLAccount);
        CreateGenJournalLine(GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Custom 2",
          -Amount / 4, GLAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostFAJournalLine(FADepreciationBook: Record "FA Depreciation Book"; Amount: Decimal; FAPostingType: Enum "FA Journal Line FA Posting Type")
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        SelectFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("Document No.", GetDocumentNo(FAJournalBatch));
        FAJournalLine.Validate("FA No.", FADepreciationBook."FA No.");
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateAndModifyFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20]; DecliningBalancePct: Decimal)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAssetNo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        FADepreciationBook.Validate("Declining-Balance %", DecliningBalancePct);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAWithFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBookCode);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", LibraryFixedAsset.GetDefaultDeprBook());
    end;

    local procedure CreateFAWithAcquisitionCost(var FADepreciationBook: Record "FA Depreciation Book")
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAWithDecliningBalanceFADeprBook(FADepreciationBook);
        CreateAndPostFAJournalLine(
          FADepreciationBook, LibraryRandom.RandDec(100, 2), FAJournalLine."FA Posting Type"::"Acquisition Cost");
        CreateFAJournalSetup(FADepreciationBook."Depreciation Book Code");
    end;

    local procedure CreateAndModifyFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FADepreciationBook: Record "FA Depreciation Book"; GenJournalBatch: Record "Gen. Journal Batch"; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGenJournalLine(GenJournalLine, FADepreciationBook, GenJournalBatch, FAPostingType, Amount, GLAccount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateFAReclassJournalLine(FANo: Code[20]; NewFANo: Code[20]; DepreciationBookCode: Code[10]; ReclassifyAcqCostPct: Decimal) DocumentNo: Code[20]
    var
        FAReclassJournalTemplate: Record "FA Reclass. Journal Template";
        FAReclassJournalBatch: Record "FA Reclass. Journal Batch";
        FAReclassJournalLine: Record "FA Reclass. Journal Line";
    begin
        FAReclassJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateFAReclassJournalBatch(FAReclassJournalBatch, FAReclassJournalTemplate.Name);
        LibraryFixedAsset.CreateFAReclassJournal(
          FAReclassJournalLine, FAReclassJournalBatch."Journal Template Name", FAReclassJournalBatch.Name);
        FAReclassJournalLine.Validate("FA Posting Date", CalcDate('<' + PeriodTxt + 'M>', WorkDate()));
        DocumentNo := LibraryUtility.GenerateGUID();
        FAReclassJournalLine.Validate("Document No.", DocumentNo);
        FAReclassJournalLine.Validate("FA No.", FANo);
        FAReclassJournalLine.Validate("New FA No.", NewFANo);
        FAReclassJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAReclassJournalLine.Validate("Reclassify Acq. Cost %", ReclassifyAcqCostPct);
        FAReclassJournalLine.Validate("Reclassify Acquisition Cost", true);
        FAReclassJournalLine.Validate("Reclassify Depreciation", true);
        FAReclassJournalLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"FA Reclass. Jnl.-Transfer", FAReclassJournalLine);
    end;

    local procedure CreateGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; DepreciationBookCode: Code[10]; GLAccount: Record "G/L Account")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        FADepreciationBook.Get(AccountNo, DepreciationBookCode);
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(100, 2), GLAccount);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FADepreciationBook: Record "FA Depreciation Book"; GenJournalBatch: Record "Gen. Journal Batch"; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal; GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FADepreciationBook."FA No.", Amount);
        GenJournalLine.Validate("Depreciation Book Code", FADepreciationBook."Depreciation Book Code");
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Document No.", FADepreciationBook."FA No.");
        GenJournalLine.Modify(true);
    end;

    local procedure PostGenJnlLineWithDeprAcqCostAndSalvageValue(FADepreciationBook: Record "FA Depreciation Book"; CurrencyCode: Code[10]; GLAccount: Record "G/L Account"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(10000, 2), GLAccount);
        GenJournalLine.Validate("Depr. Acquisition Cost", true);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Salvage Value", -Round(GenJournalLine.Amount / 10));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(LibraryERM.ConvertCurrency(GenJournalLine."Salvage Value", CurrencyCode, '', WorkDate()));
    end;

    local procedure CreateJnlLineWithBudgetedAsset(var GenJournalLine: Record "Gen. Journal Line"; FADepreciationBook: Record "FA Depreciation Book"; GenJournalBatch: Record "Gen. Journal Batch"; BudgetedFANo: Code[20]; Maintenance: Record Maintenance; GLAccount: Record "G/L Account")
    begin
        CreateGenJournalLine(
          GenJournalLine, FADepreciationBook, GenJournalBatch, GenJournalLine."FA Posting Type"::Maintenance,
          LibraryRandom.RandDec(10000, 2), GLAccount);
        GenJournalLine.Validate("Budgeted FA No.", BudgetedFANo);
        MaintenanceCodeGenJournalLine(GenJournalLine, Maintenance);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalSetupDepreciation(var DepreciationBook: Record "Depreciation Book"): Code[10]
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
        exit(FAJournalSetup."Gen. Jnl. Batch Name");
    end;

    local procedure CreateCurrencyWithExchRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure GenerateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    begin
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine."Source Currency Code" := CurrencyCode;
    end;

    local procedure GetDocumentNo(FAJournalBatch: Record "FA Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        NoSeries.Get(FAJournalBatch."No. Series");
        exit(NoSeriesCodeunit.PeekNextNo(FAJournalBatch."No. Series"));
    end;

    local procedure GetNumberOfGLBudgetEntries(BudgetName: Code[10]): Integer
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", BudgetName);
        exit(GLBudgetEntry.Count);
    end;

    local procedure GetNumberOfDaysInPeriod(PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        NoOfDaysInPeriod: Decimal;
    begin
        // special processing for February due to "border" case:
        // end of period is the end of February and start of period is not the end of January
        // in this case number of days in period should be increased
        NoOfDaysInPeriod := 30;

        if Date2DMY(PeriodStartDate, 1) <= 27 then
            exit(NoOfDaysInPeriod);

        if IsLeapDay(CalcDate('<CM>', PeriodEndDate)) then begin
            if Date2DMY(PeriodEndDate, 1) = 29 then
                NoOfDaysInPeriod += 2
            else
                NoOfDaysInPeriod += 1;
            if Date2DMY(PeriodStartDate, 1) = 28 then
                NoOfDaysInPeriod -= 1;
            NoOfDaysInPeriod += AdjustForJanEnd(PeriodStartDate);
        end else
            if (Date2DMY(PeriodEndDate, 1) = 28) and (Date2DMY(PeriodEndDate, 2) = 2) then begin
                NoOfDaysInPeriod += 2;
                NoOfDaysInPeriod += AdjustForJanEnd(PeriodStartDate);
            end;

        if (Date2DMY(PeriodStartDate, 1) = 28) and (Date2DMY(PeriodStartDate, 2) = 2) then
            if not IsLeapDay(CalcDate('<12M+CM>', PeriodStartDate)) then
                NoOfDaysInPeriod := 28.25;

        if IsLeapDay(CalcDate('<CM>', PeriodStartDate)) then
            if Date2DMY(PeriodStartDate, 1) = 29 then
                NoOfDaysInPeriod -= 1;

        exit(NoOfDaysInPeriod);
    end;

    local procedure IsLeapDay(Date: Date): Boolean
    begin
        if (Date2DMY(Date, 1) = 29) and (Date2DMY(Date, 2) = 2) then
            exit(true);
        exit(false);
    end;

    local procedure AdjustForJanEnd(Date: Date): Integer
    begin
        case Date2DMY(Date, 1) of
            29:
                exit(-1);
            30, 31:
                exit(-2);
        end;
        exit(0);
    end;

    local procedure FindAndPostGenJournalLines(DocumentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalLine.SetRange("Document No.", DocumentNo);
        GenJournalLine.FindSet();
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch.Validate("No. Series", '');
        GenJournalBatch.Modify(true);
        repeat
            GenJournalLine.Validate(Description, GenJournalBatch.Name);
            GenJournalLine.Validate("FA Posting Date", GenJournalLine."Posting Date");
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindPostedAcqCostAmt(FANo: Code[20]): Decimal
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.FindLast();
        exit(FALedgerEntry.Amount);
    end;

    local procedure MaintenanceCodeGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var Maintenance: Record Maintenance)
    begin
        GenJournalLine.Validate("Maintenance Code", Maintenance.Code);
        GenJournalLine.Modify(true);
    end;

    local procedure ModifyDepreciationBookAndGenJournalBatch(var DepreciationBook: Record "Depreciation Book")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BatchName: Code[10];
    begin
        BatchName := CreateJournalSetupDepreciation(DepreciationBook);
        DepreciationBook.Validate("Allow more than 360/365 Days", true);
        DepreciationBook.Modify(true);

        GenJournalBatch.SetRange(Name, BatchName);
        GenJournalBatch.FindFirst();
        GenJournalBatch.Validate("No. Series", '');
        GenJournalBatch.Modify(true);
    end;

    local procedure RunCalculateDepeciation(FADepreciationBook: Record "FA Depreciation Book"; DocumentNo: Code[20]; NoOfMonth: Integer)
    begin
        SetRequestOption(FADepreciationBook, DocumentNo, NoOfMonth, false);
    end;

    local procedure RunCalculateDepeciationWithBalAccount(FADepreciationBook: Record "FA Depreciation Book"; NoOfMonth: Integer) DocumentNo: Code[20]
    begin
        DocumentNo := LibraryUtility.GenerateGUID();
        SetRequestOption(FADepreciationBook, DocumentNo, NoOfMonth, true);
    end;

    local procedure RunCopyFAEntriesToGLBudget(FANo: Code[20]; DepreciationBookCode: Code[10]; GLBudgetName: Code[10]; StartingDate: Date)
    var
        FixedAsset: Record "Fixed Asset";
        CopyFAEntriesToGLBudget: Report "Copy FA Entries to G/L Budget";
    begin
        FixedAsset.SetRange("No.", FANo);
        Clear(CopyFAEntriesToGLBudget);
        CopyFAEntriesToGLBudget.UseRequestPage(false);
        CopyFAEntriesToGLBudget.SetTableView(FixedAsset);
        CopyFAEntriesToGLBudget.InitializeRequest(DepreciationBookCode, GLBudgetName, StartingDate, WorkDate(), FixedAsset."No.", false);
        CopyFAEntriesToGLBudget.SetTransferType(true, true, true, true, true, true);
        CopyFAEntriesToGLBudget.Run();
    end;

    local procedure SelectFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.DeleteAll(true);
    end;

    local procedure SetupAllowPostingToMainAssets(AllowPostingToMainAssets: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Allow Posting to Main Assets", AllowPostingToMainAssets);
        FASetup.Modify(true);
    end;

    local procedure SetupGLIntegrationInBook(var DepreciationBook: Record "Depreciation Book"; Boolean: Boolean)
    begin
        DepreciationBook.Validate("G/L Integration - Depreciation", Boolean);
        DepreciationBook.Validate("G/L Integration - Write-Down", Boolean);
        DepreciationBook.Validate("G/L Integration - Appreciation", Boolean);
        DepreciationBook.Validate("G/L Integration - Custom 1", Boolean);
        DepreciationBook.Validate("G/L Integration - Custom 2", Boolean);
        SetupPartialGLIntegrationBook(DepreciationBook, Boolean);
    end;

    local procedure SetupPartialGLIntegrationBook(var DepreciationBook: Record "Depreciation Book"; Boolean: Boolean)
    begin
        DepreciationBook.Validate("G/L Integration - Acq. Cost", Boolean);
        DepreciationBook.Validate("G/L Integration - Disposal", Boolean);
        DepreciationBook.Validate("G/L Integration - Maintenance", Boolean);
        DepreciationBook.Modify(true);
    end;

    local procedure SetRequestOption(FADepreciationBook: Record "FA Depreciation Book"; DocumentNo: Code[20]; NoOfMonth: Integer; InsertBalAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
        PostingDate: Date;
    begin
        PostingDate := CalcDate('<' + Format(NoOfMonth) + 'M>', WorkDate());
        FixedAsset.SetRange("No.", FADepreciationBook."FA No.");
        Clear(CalculateDepreciation);
        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          FADepreciationBook."Depreciation Book Code", PostingDate, false, 0, PostingDate, DocumentNo, '', InsertBalAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure UpdateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("Use FA Exch. Rate in Duplic.", true);

        // Using Random Number Generator for Default Exchange Rate.
        DepreciationBook.Validate("Default Exchange Rate", LibraryRandom.RandDec(10, 2));
        UpdatePartOfDuplicationList(DepreciationBook, true);
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

    local procedure UpdatePartOfDuplicationList(var DepreciationBook: Record "Depreciation Book"; PartOfDuplicationList: Boolean)
    begin
        DepreciationBook.Validate("Part of Duplication List", PartOfDuplicationList);
        DepreciationBook.Modify(true);
    end;

    local procedure CalcAcqCostDepreciation(FANo: Code[20]; DeprBookCode: Code[10]; OldAcquisitionAmt: Decimal; OldDepreciationAmt: Decimal; SalvageValue: Decimal) DeprAmount: Decimal
    var
        DepreciationCalculation: Codeunit "Depreciation Calculation";
    begin
        DeprAmount :=
          DepreciationCalculation.CalcRounding(
            DeprBookCode, (FindPostedAcqCostAmt(FANo) + SalvageValue) * OldDepreciationAmt / OldAcquisitionAmt);
    end;

    local procedure VerifyAmountInFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; Amount: Decimal)
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyAmountInGLEntry(SourceNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("FA Entry Type", GLEntry."FA Entry Type"::"Fixed Asset");
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.SetRange(Amount, Amount);
        GLEntry.FindFirst();
    end;

    local procedure VerifyFAJournalLine(FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.SetRange("FA No.", FANo);
        FAJournalLine.FindFirst();
        FAJournalLine.TestField("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.TestField(Amount, Amount);
    end;

    local procedure VerifyFALedgerEntry(FAPostingType: Enum "FA Ledger Entry FA Posting Type"; FANo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        GeneralLedgerSetup.Get();
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, FALedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, FALedgerEntry.FieldCaption(Amount), Amount, FALedgerEntry.TableCaption()));
    end;

    local procedure VerifyLastFALedgEntryAmount(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; ExpectedAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindLast();
        FALedgerEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntry(SourceNo: Code[20]; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("FA Entry Type", GLEntry."FA Entry Type"::"Fixed Asset");
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyMaintenanceInGLEntry(SourceNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("FA Entry Type", GLEntry."FA Entry Type"::Maintenance);
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyMaintenanceLedgerEntry(FANo: Code[20]; Amount: Decimal)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.FindFirst();
        MaintenanceLedgerEntry.TestField(Amount, Amount);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler
    end;

    local procedure FindCustomer(var Customer: Record Customer)
    begin
        // Filter Customer so that errors are not generated due to mandatory fields.
        Customer.SetFilter("Customer Posting Group", '<>''''');
        Customer.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Customer.SetFilter("Payment Terms Code", '<>''''');
        Customer.SetRange(Blocked, Customer.Blocked::" ");
        // For Complete Shipping Advice, partial shipments are disallowed, hence select Partial.
        Customer.SetRange("Shipping Advice", Customer."Shipping Advice"::Partial);
        Customer.FindFirst();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if 0 <> StrPos(Question, CompletionStatsTok) then
            Reply := false
        else
            Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchesModalPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueBoolean(), GeneralJournalBatches."Allow Payment Export".Visible(), '');
    end;
}

