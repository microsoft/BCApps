codeunit 134165 "Payroll Extension Support Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payroll Extension]
    end;

    var
        Assert: Codeunit Assert;
        PayrollServiceExtensionMock: Codeunit "Payroll Service Extension Mock";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        NotFoundSuffixTxt: Label ' could not be found.';
        DisabledSuffixTxt: Label ' is disabled.', Comment = '%1 Payroll Service Name';
        SelectPayrollServiceToUseTxt: Label 'Several payroll services are installed and enabled. Select a service you want to use.';
        SelectPayrollServiceToEnableTxt: Label 'Select a payroll service you want to enable and use.';
        EnablePayrollServicesTxt: Label 'All payroll services are disabled. Do you want to enable a payroll service?';
        WrongStrMenuErr: Label 'Wrong StrMenu is shown.';
        WrongConfirmErr: Label 'Wrong Confirm is shown.';
        WrongImportPayrollAvailableErr: Label 'Action "Import Payroll Transactions" is not available, but it must be.';
        WrongImportPayrollUnavailableErr: Label 'Action "Import Payroll Transactions" is available, but it must not be.';
        WrongCountOfPayrollServicesErr: Label 'Wrong count of payroll services.';
        WrongCountOfJournalLinesErr: Label 'Wrong count of journal lines.';
        SelectSecondChoice: Integer;
        SelectNothingChoice: Integer;
        ConfirmYesChoice: Boolean;
        ConfirmNoChoice: Boolean;
        SuccessfulSetupChoice: Option;
        FailedSetupChoice: Option;
        IncorrectLinesInJournalErr: Label 'Incorrect lines are shown in general journal.';
        UnunstallSetupChoice: Option;

    local procedure Initialize()
    var
        ServiceConnection: Record "Service Connection";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        GenJnlManagement: Codeunit GenJnlManagement;
    begin
        LibraryVariableStorage.Clear();
        CleanUp();

        if IsInitialized then
            exit;

        SelectNothingChoice := 0;
        SelectSecondChoice := 2;
        ConfirmYesChoice := true;
        ConfirmNoChoice := false;
        SuccessfulSetupChoice := ServiceConnection.Status::Enabled;
        FailedSetupChoice := ServiceConnection.Status::Disabled;
        UnunstallSetupChoice := ServiceConnection.Status::" ";

        LibraryERMCountryData.RemoveBlankGenJournalTemplate();

        LibraryRandom.SetSeed(1);
        BindSubscription(PayrollServiceExtensionMock);

        IsInitialized := true;
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"General Journal");
        Commit();
    end;

    local procedure CleanUp()
    begin
        PayrollServiceExtensionMock.CleanUp();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayrollActionNotVisibleWhenThereAreNoExtensionsInstalled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, TempSetupServiceConnection.Status::" ");

        // Execute
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(false, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollUnavailableErr);

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayrollWhenAllExtensionsUnunstalledAfterJournalHasOpened()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, TempSetupServiceConnection.Status::Enabled);

        // Execute
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        TempSetupServiceConnection.DeleteAll();
        PayrollServiceExtensionMock.SetAvailableServiceConnections(TempSetupServiceConnection);
        asserterror GeneralJournal.ImportPayrollTransactions.Invoke();
        Assert.ExpectedError(NotFoundSuffixTxt);

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionInstalledAndEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, TempSetupServiceConnection.Status::Enabled);

        // Execute
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();

        // Verify
        VerifyLineShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionInstalledAndEnabledWhenAnotherLineExist()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalledAndEnabledWhenAnotherLineExist(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, GenJournalLine);

        // Execute
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.AreEqual(2, GenJournalLine.Count, WrongCountOfJournalLinesErr);

        // Verify
        VerifyLineShownInJournal(GenJournalLine, GeneralJournal);
        // PAG39 (General journal) opens up in simple mode by default which filters on document number
        // so to get to next document number we need to invoke NextDocNumberTrx.
        GeneralJournal.NextDocNumberTrx.Invoke();
        VerifyLineShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,PayrollServiceSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionInstalledAndDisabledThenConfirmedAndEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(SuccessfulSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,PayrollServiceSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionInstalledAndDisabledThenConfirmedButStillDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(FailedSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        asserterror GeneralJournal.ImportPayrollTransactions.Invoke();
        Assert.ExpectedError(DisabledSuffixTxt);
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,PayrollServiceSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionInstalledAndDisabledThenConfirmedButUninstalled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(UnunstallSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        asserterror GeneralJournal.ImportPayrollTransactions.Invoke();
        Assert.ExpectedError(NotFoundSuffixTxt);
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionInstalledAndDisabledThenDeclined()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmNoChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,PayrollServiceAssistedSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionWithIncompleteAssistedSetupDisabledThenConfirmedAndEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionWithAssistedSetupInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(SuccessfulSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,PayrollServiceAssistedSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionWithIncompleteAssistedSetupDisabledThenConfirmedButStillDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionWithAssistedSetupInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(FailedSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        asserterror GeneralJournal.ImportPayrollTransactions.Invoke();
        Assert.ExpectedError(DisabledSuffixTxt);
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,PayrollServiceAssistedSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollSingleExtensionWithIncompleteAssistedSetupDisabledThenConfirmedButUninstalled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupSingleExtensionWithAssistedSetupInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(UnunstallSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        asserterror GeneralJournal.ImportPayrollTransactions.Invoke();
        Assert.ExpectedError(NotFoundSuffixTxt);
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportPayrollMultipleExtensionsInstalledOneEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        CreateMockPayrollService(TempSetupServiceConnection, TempSetupServiceConnection.Status::Disabled);
        CreateMockPayrollService(TempSetupServiceConnection, TempSetupServiceConnection.Status::Enabled);
        SelectGenJournalBatch(GenJournalBatch);
        CreateMockGenJournalLine(TempGenJournalLine, GenJournalBatch);
        PayrollServiceExtensionMock.SetAvailableServiceConnections(TempSetupServiceConnection);
        PayrollServiceExtensionMock.SetNewGenJournalLine(TempGenJournalLine);
        Assert.AreEqual(2, TempSetupServiceConnection.Count, WrongCountOfPayrollServicesErr);
        Assert.AreEqual(1, TempGenJournalLine.Count, WrongCountOfJournalLinesErr);

        // Execute
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('SelectPayrollServiceHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollMultipleExtensionsInstalledAllEnabledThenOneSelected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupTwoExtensionsInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Enabled, TempSetupServiceConnection.Status::Enabled);

        // Execute
        LibraryVariableStorage.Enqueue(SelectPayrollServiceToUseTxt);
        LibraryVariableStorage.Enqueue(SelectSecondChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('SelectPayrollServiceHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollMultipleExtensionsInstalledAllEnabledThenNothingSelected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupTwoExtensionsInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Enabled, TempSetupServiceConnection.Status::Enabled);

        // Execute
        LibraryVariableStorage.Enqueue(SelectPayrollServiceToUseTxt);
        LibraryVariableStorage.Enqueue(SelectNothingChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,SelectPayrollServiceHandler,PayrollServiceSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollMultipleExtensionsInstalledAllDisabledThenConfirmedOneSelectedAndEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupTwoExtensionsInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Disabled, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(SelectPayrollServiceToEnableTxt);
        LibraryVariableStorage.Enqueue(SelectSecondChoice);
        LibraryVariableStorage.Enqueue(SuccessfulSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();

        // Verify
        VerifyLineShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,SelectPayrollServiceHandler,PayrollServiceSetupMockHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrollMultipleExtensionsInstalledAllDisabledThenConfirmedOneSelectedButStillDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupTwoExtensionsInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Disabled, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(SelectPayrollServiceToEnableTxt);
        LibraryVariableStorage.Enqueue(SelectSecondChoice);
        LibraryVariableStorage.Enqueue(FailedSetupChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        asserterror GeneralJournal.ImportPayrollTransactions.Invoke();
        Assert.ExpectedError(DisabledSuffixTxt);

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler,SelectPayrollServiceHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrolMultipleExtensionsInstalledAllDisabledThenConfirmedButNothingSelected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupTwoExtensionsInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Disabled, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmYesChoice);
        LibraryVariableStorage.Enqueue(SelectPayrollServiceToEnableTxt);
        LibraryVariableStorage.Enqueue(SelectNothingChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    [Test]
    [HandlerFunctions('EnablePayrollServiceHandler')]
    [Scope('OnPrem')]
    procedure TestImportPayrolMultipleExtensionsInstalledAllDisabledThenDeclined()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempSetupServiceConnection: Record "Service Connection" temporary;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        SetupTwoExtensionsInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          TempSetupServiceConnection.Status::Disabled, TempSetupServiceConnection.Status::Disabled);

        // Execute
        LibraryVariableStorage.Enqueue(EnablePayrollServicesTxt);
        LibraryVariableStorage.Enqueue(ConfirmNoChoice);
        OpenGeneralJournal(GeneralJournal, GenJournalBatch.Name);
        Assert.AreEqual(true, GeneralJournal.ImportPayrollTransactions.Visible(), WrongImportPayrollAvailableErr);
        GeneralJournal.ImportPayrollTransactions.Invoke();
        LibraryVariableStorage.AssertEmpty();

        // Verify
        VerifyLineNotShownInJournal(TempGenJournalLine, GeneralJournal);

        // Clean Up
        CleanUp();
    end;

    local procedure SetupSingleExtensionInstalled(var TempSetupServiceConnection: Record "Service Connection" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalBatch: Record "Gen. Journal Batch"; ServiceStatus: Option)
    begin
        SetupTwoExtensionsInstalled(
          TempSetupServiceConnection, TempGenJournalLine, GenJournalBatch,
          ServiceStatus, TempSetupServiceConnection.Status::" ");
    end;

    local procedure SetupTwoExtensionsInstalled(var TempSetupServiceConnection: Record "Service Connection" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalBatch: Record "Gen. Journal Batch"; ServiceOneStatus: Option; ServiceTwoStatus: Option)
    var
        ServiceCount: Integer;
    begin
        if ServiceOneStatus <> TempSetupServiceConnection.Status::" " then begin
            CreateMockPayrollService(TempSetupServiceConnection, ServiceOneStatus);
            ServiceCount += 1;
        end;
        if ServiceTwoStatus <> TempSetupServiceConnection.Status::" " then begin
            CreateMockPayrollService(TempSetupServiceConnection, ServiceOneStatus);
            ServiceCount += 1;
        end;
        SelectGenJournalBatch(GenJournalBatch);
        CreateMockGenJournalLine(TempGenJournalLine, GenJournalBatch);
        PayrollServiceExtensionMock.SetAvailableServiceConnections(TempSetupServiceConnection);
        PayrollServiceExtensionMock.SetNewGenJournalLine(TempGenJournalLine);
        Assert.AreEqual(ServiceCount, TempSetupServiceConnection.Count, WrongCountOfPayrollServicesErr);
        Assert.AreEqual(1, TempGenJournalLine.Count, WrongCountOfJournalLinesErr);
    end;

    local procedure SetupSingleExtensionWithAssistedSetupInstalled(var TempSetupServiceConnection: Record "Service Connection" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalBatch: Record "Gen. Journal Batch"; ServiceStatus: Option)
    begin
        CreateMockPayrollServiceExtended(TempSetupServiceConnection, ServiceStatus, true);
        SelectGenJournalBatch(GenJournalBatch);
        CreateMockGenJournalLine(TempGenJournalLine, GenJournalBatch);
        PayrollServiceExtensionMock.SetAvailableServiceConnections(TempSetupServiceConnection);
        PayrollServiceExtensionMock.SetNewGenJournalLine(TempGenJournalLine);
        Assert.AreEqual(1, TempSetupServiceConnection.Count, WrongCountOfPayrollServicesErr);
        Assert.AreEqual(1, TempGenJournalLine.Count, WrongCountOfJournalLinesErr);
    end;

    local procedure SetupSingleExtensionInstalledAndEnabledWhenAnotherLineExist(var TempSetupServiceConnection: Record "Service Connection" temporary; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateMockPayrollService(TempSetupServiceConnection, TempSetupServiceConnection.Status::Enabled);
        SelectGenJournalBatch(GenJournalBatch);
        CreateRealGenJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        Assert.AreEqual(1, GenJournalLine.Count, WrongCountOfJournalLinesErr);
        CreateMockGenJournalLine(TempGenJournalLine, GenJournalBatch);
        PayrollServiceExtensionMock.SetAvailableServiceConnections(TempSetupServiceConnection);
        PayrollServiceExtensionMock.SetNewGenJournalLine(TempGenJournalLine);
        Assert.AreEqual(1, TempSetupServiceConnection.Count, WrongCountOfPayrollServicesErr);
        Assert.AreEqual(1, TempGenJournalLine.Count, WrongCountOfJournalLinesErr);
    end;

    local procedure OpenGeneralJournal(var GeneralJournal: TestPage "General Journal"; JournalBatchName: Text)
    begin
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
    end;

    local procedure CreateMockPayrollService(var TempServiceConnection: Record "Service Connection" temporary; ServiceStatus: Option)
    begin
        CreateMockPayrollServiceExtended(TempServiceConnection, ServiceStatus, false);
    end;

    local procedure CreateMockPayrollServiceExtended(var TempServiceConnection: Record "Service Connection" temporary; ServiceStatus: Option; CreateSetup: Boolean)
    var
        Customer: Record Customer;
    begin
        TempServiceConnection.Init();
        TempServiceConnection."No." := Format(CreateGuid());
        TempServiceConnection.Name := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(TempServiceConnection.Name));
        TempServiceConnection.Status := ServiceStatus;
        TempServiceConnection."Page ID" := PAGE::"Customer Card";
        LibrarySales.CreateCustomer(Customer);
        TempServiceConnection."Record ID" := Customer.RecordId;
        if CreateSetup then begin
            CreateAssistedSetup(PAGE::"General Ledger Setup");
            TempServiceConnection."Assisted Setup Page ID" := PAGE::"General Ledger Setup";
        end;
        TempServiceConnection.Insert();
    end;

    local procedure CreateMockGenJournalLine(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CreateGenJournalLine(TempGenJournalLine, GenJournalBatch);
    end;

    local procedure CreateRealGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        // Clear General Journal Lines to make sure that no line exits before creating new General Journal Lines.
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        if GenJournalBatch."No. Series" <> '' then begin
            GenJournalBatch.Validate("No. Series", '');
            GenJournalBatch.Modify();
        end;
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.SetRange("Line No.");
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Line No.", GetGenJournalNewLineNo(GenJournalBatch));
        GenJournalLine.Insert(true);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", LibrarySales.CreateCustomerNo());
        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
        GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        GenJournalLine.Validate(
          Description, CopyStr(StrSubstNo('%1:%2', GenJournalLine."Line No.", CreateGuid()), 1, MaxStrLen(GenJournalLine.Description)));
        GenJournalLine.Validate(Comment, Format(CreateGuid()));
        GenJournalLine.Modify(true);
        GenJournalLine.Reset();
    end;

    local procedure CreateAssistedSetup(PageID: Integer)
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertAssistedSetup('', '', '', 0, ObjectType::Page, PageID, "Assisted Setup Group"::Uncategorized, '', "Video Category"::Uncategorized, '');
    end;

    local procedure GetGenJournalNewLineNo(var GenJournalBatch: Record "Gen. Journal Batch"): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        LineNo: Integer;
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindLast() then
            LineNo := GenJournalLine."Line No." + 10000
        else
            LineNo := 10000;
        exit(LineNo);
    end;

    local procedure CompareRecordAndJournal(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal."Document No.".AssertEquals(TempGenJournalLine."Document No.");
        GeneralJournal."Document Type".AssertEquals(TempGenJournalLine."Document Type");
        GeneralJournal."Account Type".AssertEquals(TempGenJournalLine."Account Type");
        GeneralJournal."Account No.".AssertEquals(TempGenJournalLine."Account No.");
        GeneralJournal."Bal. Account Type".AssertEquals(TempGenJournalLine."Bal. Account Type");
        GeneralJournal."Bal. Account No.".AssertEquals(TempGenJournalLine."Bal. Account No.");
    end;

    local procedure VerifyLineShownInJournal(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GeneralJournal: TestPage "General Journal")
    var
        Found: Boolean;
    begin
        GeneralJournal.First();
        repeat
            if TempGenJournalLine.Description = GeneralJournal.Description.Value then begin
                Found := true;
                CompareRecordAndJournal(TempGenJournalLine, GeneralJournal);
            end;
        until not GeneralJournal.Next();
        Assert.AreEqual(true, Found, IncorrectLinesInJournalErr);
    end;

    local procedure VerifyLineNotShownInJournal(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GeneralJournal: TestPage "General Journal")
    begin
        GeneralJournal.First();
        repeat
            Assert.AreNotEqual(TempGenJournalLine."Document No.", GeneralJournal."Document No.".Value, IncorrectLinesInJournalErr);
        until not GeneralJournal.Next();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SelectPayrollServiceHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.AreEqual(Instruction, LibraryVariableStorage.DequeueText(), WrongStrMenuErr);
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure EnablePayrollServiceHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(Question, LibraryVariableStorage.DequeueText(), WrongConfirmErr);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PayrollServiceSetupMockHandler(var CustomerCard: TestPage "Customer Card")
    var
        TempSetupServiceConnection: Record "Service Connection" temporary;
        Customer: Record Customer;
        NewStatus: Integer;
    begin
        NewStatus := LibraryVariableStorage.DequeueInteger();
        PayrollServiceExtensionMock.GetAvailableServiceConnections(TempSetupServiceConnection);
        Customer.Get(CustomerCard."No.".Value);
        TempSetupServiceConnection.SetRange("Record ID", Customer.RecordId);
        TempSetupServiceConnection.FindFirst();
        if NewStatus = TempSetupServiceConnection.Status::" " then
            TempSetupServiceConnection.Delete()
        else begin
            TempSetupServiceConnection.Validate(Status, NewStatus);
            TempSetupServiceConnection.Modify();
        end;
        TempSetupServiceConnection.Reset();
        PayrollServiceExtensionMock.SetAvailableServiceConnections(TempSetupServiceConnection);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PayrollServiceAssistedSetupMockHandler(var GeneralLedgerSetup: TestPage "General Ledger Setup")
    var
        TempSetupServiceConnection: Record "Service Connection" temporary;
        NewStatus: Integer;
    begin
        NewStatus := LibraryVariableStorage.DequeueInteger();
        PayrollServiceExtensionMock.GetAvailableServiceConnections(TempSetupServiceConnection);
        TempSetupServiceConnection.SetRange("Assisted Setup Page ID", PAGE::"General Ledger Setup");
        TempSetupServiceConnection.FindFirst();
        if NewStatus = TempSetupServiceConnection.Status::" " then
            TempSetupServiceConnection.Delete()
        else begin
            TempSetupServiceConnection.Validate(Status, NewStatus);
            TempSetupServiceConnection.Modify();
        end;
        TempSetupServiceConnection.Reset();
        PayrollServiceExtensionMock.SetAvailableServiceConnections(TempSetupServiceConnection);
    end;
}

