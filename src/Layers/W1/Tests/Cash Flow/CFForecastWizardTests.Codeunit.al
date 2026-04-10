codeunit 139315 "CF Forecast Wizard Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Forecast] [Wizard] [UI]
    end;

    var
        Assert: Codeunit Assert;
        DefaultTxt: Label 'Default';
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        UpdateFrequency: Option Never,Daily,Weekly;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        CashFlowManagement: Codeunit "Cash Flow Management";
        LibraryAzureKVMockMgmt: Codeunit "Library - Azure KV Mock Mgmt.";
        IsInitialized: Boolean;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CF Forecast Wizard Tests");
        LibraryAzureKVMockMgmt.InitMockAzureKeyvaultSecretProvider();
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        DeleteCashFlowSetup();
        CashFlowManagement.DeleteJobQueueEntries();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"CF Forecast Wizard Tests");
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"CF Forecast Wizard Tests");
    end;

    local procedure DeleteCashFlowSetup()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowAccountComment: Record "Cash Flow Account Comment";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowWorksheetLine: Record "Cash Flow Worksheet Line";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        CashFlowManualExpense: Record "Cash Flow Manual Expense";
        CashFlowReportSelection: Record "Cash Flow Report Selection";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        CashFlowForecast.DeleteAll();
        CashFlowAccount.DeleteAll();
        CashFlowAccountComment.DeleteAll();
        CashFlowSetup.DeleteAll();
        CashFlowWorksheetLine.DeleteAll();
        CashFlowForecastEntry.DeleteAll();
        CashFlowManualRevenue.DeleteAll();
        CashFlowManualExpense.DeleteAll();
        CashFlowReportSelection.DeleteAll();
        CashFlowChartSetup.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenNotFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CashFlowForecastWizard: TestPage "Cash Flow Forecast Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The cash flow forecast wizard is run to the end but not finished
        RunWizardToCompletion(CashFlowForecastWizard, UpdateFrequency::Never);
        CashFlowForecastWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Cash Flow Forecast Wizard"), 'Set Up Cash Flow Forecast status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyStatusNotCompletedWhenExitRightAway()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CashFlowForecastWizard: TestPage "Cash Flow Forecast Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The Cash Flow Forecast Wizard is exited right away
        CashFlowForecastWizard.Trap();
        PAGE.Run(PAGE::"Cash Flow Forecast Wizard");
        CashFlowForecastWizard.Close();

        // [THEN] Status of Cash Flow Forecast remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Cash Flow Forecast Wizard"), 'Set Up Cash Flow Forecast status should not be completed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStatusCompletedWhenFinished()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CashFlowForecastWizard: TestPage "Cash Flow Forecast Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The Cash Flow Forecast Wizard is completed
        RunWizardToCompletion(CashFlowForecastWizard, UpdateFrequency::Never);
        CashFlowForecastWizard.ActionFinish.Invoke();

        // [THEN] Status of the setup is set to Completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Cash Flow Forecast Wizard"), 'Set Up Cash Flow Forecast status should be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyWizardNotExitedWhenConfirmIsNo()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CashFlowForecastWizard: TestPage "Cash Flow Forecast Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The data migration wizard is closed but closing is not confirmed
        CashFlowForecastWizard.Trap();
        PAGE.Run(PAGE::"Cash Flow Forecast Wizard");
        CashFlowForecastWizard.Close();

        // [THEN] Status of assisted setup remains Not Completed
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, PAGE::"Cash Flow Forecast Wizard"), 'Set Up Cash Flow Forecast status should not be completed.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VerifyLiquidFundsGLAccountFilterDefaultValue()
    var
        CashFlowForecastWizard: TestPage "Cash Flow Forecast Wizard";
    begin
        // [GIVEN] A newly setup company
        Initialize();

        // [WHEN] The setup page is shown
        CashFlowForecastWizard.Trap();
        PAGE.Run(PAGE::"Cash Flow Forecast Wizard");
        CashFlowForecastWizard.ActionNext.Invoke(); // Setup page

        // [THEN] The LiquidFundsGLAccountFilter has the correct value
        Assert.AreEqual(CashFlowForecastWizard.LiquidFundsGLAccountFilter.Value,
          GetLiquidFundsGLAccountFilter(), 'The liquid funds filter has a wrong value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCashFlowSetupWhenWizardCompleted()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowAccount: Record "Cash Flow Account";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        CashFlowForecastWizard: TestPage "Cash Flow Forecast Wizard";
    begin
        // [GIVEN] A newly setup company (preconditions are verified)
        Initialize();
        Assert.RecordIsEmpty(CashFlowForecast);
        Assert.RecordIsEmpty(CashFlowAccount);
        Assert.RecordIsEmpty(CashFlowSetup);
        Assert.RecordIsEmpty(CashFlowForecastEntry);
        Assert.RecordIsEmpty(CashFlowChartSetup);

        // [GIVEN] Mock customer ledger entry
        LibraryCashFlow.MockCashFlowCustOverdueData();

        // [WHEN] The Cash Flow Forecast Wizard is completed
        RunWizardToCompletion(CashFlowForecastWizard, UpdateFrequency::Never);
        CashFlowForecastWizard.ActionFinish.Invoke();

        // [THEN] Cash Flow Forecast is set up and data is available for the chart to be consumed
        Assert.RecordIsNotEmpty(CashFlowForecast);
        Assert.RecordIsNotEmpty(CashFlowAccount);
        Assert.RecordIsNotEmpty(CashFlowSetup);
        Assert.RecordIsNotEmpty(CashFlowForecastEntry);
        Assert.RecordIsNotEmpty(CashFlowChartSetup);

        Assert.IsTrue(CashFlowForecast.Get(DefaultTxt), 'No DEFAULT Cash Flow Forecast exists');
        Assert.RecordCount(CashFlowAccount, 12);

        // [THEN] "No." = '4-CASH FLOW MANUAL E' of CF Account with "Source Type" = "Cash Flow Manual Expense"
        // OptionString: ,Receivables,Payables,Liquid Funds,Cash Flow Manual Expense,Cash Flow Manual Revenue,Sales Orders,Purchase Orders,Fixed Assets Budget,Fixed Assets Disposal,Service Orders,G/L Budget,,,Job,Tax
        CashFlowAccount.SetRange("Source Type", CashFlowAccount."Source Type"::"Cash Flow Manual Expense");
        CashFlowAccount.FindFirst();
        CashFlowAccount.TestField("No.", '4-CASH FLOW MANUAL E');
    end;

    local procedure RunWizardToCompletion(var CashFlowForecastWizard: TestPage "Cash Flow Forecast Wizard"; Frequency: Option)
    begin
        CashFlowForecastWizard.Trap();
        PAGE.Run(PAGE::"Cash Flow Forecast Wizard");

        CashFlowForecastWizard.ActionNext.Invoke(); // Setup page
        CashFlowForecastWizard.ActionBack.Invoke(); // Welcome page
        Assert.IsFalse(CashFlowForecastWizard.ActionBack.Enabled(), 'Back should not be enabled at the end of the wizard');
        CashFlowForecastWizard.ActionNext.Invoke(); // Setup page
        CashFlowForecastWizard.UpdateFrequency.SetValue(Frequency);
        CashFlowForecastWizard.ActionNext.Invoke(); // Azure AI Page
        CashFlowForecastWizard.ActionNext.Invoke(); // Tax page
        CashFlowForecastWizard.ActionNext.Invoke(); // That's it page
        Assert.IsTrue(CashFlowForecastWizard.ActionBack.Enabled(), 'Back should be enabled at the end of the wizard');
        Assert.IsFalse(CashFlowForecastWizard.ActionNext.Enabled(), 'Next should not be enabled at the end of the wizard');
    end;

    local procedure GetLiquidFundsGLAccountFilter() CashAccountFilter: Text
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Additional Report Definition", GLAccountCategory."Additional Report Definition"::"Cash Accounts");
        if not GLAccountCategory.FindSet() then
            exit;

        CashAccountFilter := GLAccountCategory.GetTotaling();
        while GLAccountCategory.Next() <> 0 do
            CashAccountFilter += '|' + GLAccountCategory.GetTotaling();

        CashAccountFilter := CashAccountFilter.TrimStart('|').TrimEnd('|');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

