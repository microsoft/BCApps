codeunit 144073 "UT Fiscal Year"
{
    // Miscellaneous unit test cases related to Fiscal Year Area.
    //   8. Purpose of this test is to verify OnRunTrigger Execution for Fiscal Year Closing Steps Page (PAG10818).
    //   9. Purpose of the test is to verify error while Fiscally closing all closed Fiscal Years.
    //  10. Purpose of this test is to verify error while Fiscally Closing an open Fiscal Year.
    //  11. Purpose of the test is to verify error while Fiscally Closing Fiscal Year with unbalanced GL Account.
    //  12. Purpose of this test is to verify error while Fiscally Closing Fiscal Year with unposted General Journal Line.
    //  13. Purpose of this test is to verify error while running Create Fiscal Year Report.
    //  14. Purpose of this test is to verify error message while setting value on New Fiscal Year field of Accounting Periods Page.
    //  15. Purpose of the this test is to verify that Fiscally Closed field is uneditable on Accounting Periods Page.
    //  16. Purpose of the test is to verify Error while reopening a Fiscally Closed Period.
    // 
    // Covers Test Cases for WI - 345879
    // ------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                      TFS ID
    // ------------------------------------------------------------------------------------------------------------------
    // OnRunFiscalYearClosingStepsPage                                                                         151798
    // 
    // Covers Test Cases for WI - 344839
    // -------------------------------------------------------------------------------------
    // Test Function Name                                              TFS ID
    // -------------------------------------------------------------------------------------
    // OnRunFiscallyCloseClosedFiscalYearError                         151861,151862,151879
    // OnRunFiscallyCloseOpenFiscalYearError                           151867,151910,152023
    // OnRunFiscallyCloseFiscalYearUnbalancedGLError                   152600
    // OnRunFiscallyCloseFiscalYearGenJournalLineError                 152023
    // OnRunCreateFiscalYearReportError                                151862
    // OnValidateNewFiscalYearAccPeriodsPage                           151879, 152600
    // FiscallyClosedFieldUneditableOnAccPeriodsPage                   151802
    // ReopenFiscallyClosedFiscalPeriodError                           151792, 151740

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        DialogTxt: Label 'Dialog';
        UneditableErr: Label '%1 Field must be uneditable.';
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('AccountingPeriodsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunFiscalYearClosingStepsPage()
    var
        FiscalYearClosingSteps: TestPage "Fiscal Year Closing Steps";
    begin
        // Purpose of this test is to verify OnRunTrigger Execution for Fiscal Year Closing Steps Page (PAG10818).

        // Setup.
        FiscalYearClosingSteps.OpenEdit();

        // Exercise.
        FiscalYearClosingSteps."Accounting Periods".Invoke();  // Opens AccountingPeriodsPageHandler.

        // Verify: Verify that Accounting Periods Page successfully opened.

        // Tear Down.
        FiscalYearClosingSteps.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunFiscallyCloseClosedFiscalYearError()
    var
        AccountingPeriod: Record "Accounting Period";
        Counter: Integer;
    begin
        // Purpose of the test is to verify error while Fiscally closing all closed Fiscal Years.

        // Setup: Close all fiscal years in system.
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);
        for Counter := 1 to AccountingPeriod.Count - 1 do
            CODEUNIT.Run(CODEUNIT::"Fiscal Year-Close", AccountingPeriod);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Fiscally Closed", false);

        // Exercise: Try to Fiscally Close all fiscal years.
        for Counter := 1 to AccountingPeriod.Count do
            asserterror CODEUNIT.Run(CODEUNIT::"Fiscal Year-FiscalClose", AccountingPeriod);

        // Verify: Verify actual error: You must create a new fiscal year before you can fiscally close the old year.
        Assert.ExpectedErrorCode(DialogTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunFiscallyCloseOpenFiscalYearError()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // Purpose of this test is to verify error while Fiscally Closing an open Fiscal Year.

        // Setup.
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Fiscal Year-FiscalClose", AccountingPeriod);

        // Verify: Verify actual Error: The fiscal year from XXXXXX to YYYYYY must first be closed before it can be fiscally closed.
        Assert.ExpectedErrorCode(DialogTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunFiscallyCloseFiscalYearUnbalancedGLError()
    var
        AccountingPeriod: Record "Accounting Period";
        Counter: Integer;
    begin
        // Purpose of the test is to verify error while Fiscally Closing Fiscal Year with unbalanced GL Account.

        // Setup: Close Fiscal Year an then try to Fiscally Close next year.
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);
        for Counter := 1 to AccountingPeriod.Count - 1 do
            CODEUNIT.Run(CODEUNIT::"Fiscal Year-Close", AccountingPeriod);
        AccountingPeriod.SetRange(Closed, true);
        AccountingPeriod.SetRange("Fiscally Closed", false);

        // Exercise.
        asserterror
          for Counter := 1 to AccountingPeriod.Count do
            CODEUNIT.Run(CODEUNIT::"Fiscal Year-FiscalClose", AccountingPeriod);

        // Verify: Verify actual error: The Income Statement G/L accounts are not balanced at date XXYYZZ. Please run the batch job Close Income Statement again before fiscally closing the fiscal year from Date to Date.
        Assert.ExpectedErrorCode(DialogTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunFiscallyCloseFiscalYearGenJournalLineError()
    var
        AccountingPeriod: Record "Accounting Period";
        Counter: Integer;
    begin
        // Purpose of this test is to verify error while Fiscally Closing Fiscal Year with unposted General Journal Line.

        // Setup: Close Fiscal Year and then create General Journal Line in closed year.
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);
        for Counter := 1 to AccountingPeriod.Count - 1 do
            CODEUNIT.Run(CODEUNIT::"Fiscal Year-Close", AccountingPeriod);
        CreateGeneralJournalLine();
        AccountingPeriod.Reset();

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Fiscal Year-FiscalClose", AccountingPeriod);

        // Verify: Verify actual error:
        // To fiscally close the fiscal year from 01/01/13 to 31/12/13, you must first post or delete all unposted general journal lines for this fiscal year.
        // Journal Template Name='',Journal Batch Name='',Line No.='0'
        Assert.ExpectedErrorCode(DialogTxt);
    end;

    [Test]
    [HandlerFunctions('CreateFiscalYearRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunCreateFiscalYearReportError()
    begin
        // Purpose of this test is to verify error while running Create Fiscal Year Report.

        // Setup and Exercise: Run report Create Fiscal Year.
        asserterror REPORT.Run(REPORT::"Create Fiscal Year");  // Invokes CreateFiscalYearRequestPageHandler.

        // Verify: Verify Error Message.
        // Actual Error Message: It is not allowed to have more than two open fiscal years. Please fiscally close the oldest open fiscal year first.
        Assert.ExpectedErrorCode(DialogTxt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateNewFiscalYearAccPeriodsPage()
    var
        AccountingPeriods: TestPage "Accounting Periods";
    begin
        // Purpose of this test is to verify error message while setting value on New Fiscal Year field of Accounting Periods Page.

        // Setup.
        AccountingPeriods.OpenView();
        AccountingPeriods.Last();

        // Exercise.
        asserterror AccountingPeriods."New Fiscal Year".SetValue(true);

        // Verify: Verify actual error message: Validation error for Field:New Fiscal Year,  Message = 'It is not allowed to have more than two open fiscal years. Please fiscally close the oldest open fiscal year first.
        Assert.ExpectedErrorCode('TestValidation');

        // Tear Down.
        AccountingPeriods.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FiscallyClosedFieldUneditableOnAccPeriodsPage()
    var
        AccountingPeriods: TestPage "Accounting Periods";
    begin
        // Purpose of the this test is to verify that Fiscally Closed field is uneditable on Accounting Periods Page.

        // Setup and Exercise.
        AccountingPeriods.OpenEdit();

        // Verify.
        Assert.IsFalse(
          AccountingPeriods."Fiscally Closed".Editable(), StrSubstNo(UneditableErr, AccountingPeriods."Fiscally Closed".Caption));

        // Tear Down.
        AccountingPeriods.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReopenFiscallyClosedFiscalPeriodError()
    var
        AccountingPeriods: TestPage "Accounting Periods";
    begin
        // Purpose of the test is to verify Error while reopening a Fiscally Closed Period.

        // Setup.
        AccountingPeriods.OpenView();
        AccountingPeriods."F&iscally Close Year".Invoke();
        AccountingPeriods.FILTER.SetFilter("Fiscally Closed", Format(true));

        // Exercise.
        asserterror AccountingPeriods.ReopenFiscalPeriod.Invoke();

        // Verify: Verify Error Message while reopening a Fiscally Closed Period.
        // Actual error message: The period you are trying to reopen belongs to a fiscal year that has been fiscally closed.
        // Once a fiscal year is fiscally closed, you cannot reopen any of the periods in that fiscal year.
        Assert.ExpectedErrorCode('TestWrapped:Dialog');

        // Tear Down.
        AccountingPeriods.Close();
    end;

    local procedure CreateGeneralJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine."Posting Date" := GetFirstAccountingPeriodDate();
        GenJournalLine.Insert();
    end;

    local procedure GetFirstAccountingPeriodDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("Fiscally Closed", false);
        AccountingPeriod.FindFirst();
        exit(AccountingPeriod."Starting Date");
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccountingPeriodsPageHandler(var AccountingPeriods: TestPage "Accounting Periods")
    begin
        AccountingPeriods.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateFiscalYearRequestPageHandler(var CreateFiscalYear: TestRequestPage "Create Fiscal Year")
    begin
        CreateFiscalYear.OK().Invoke();
    end;
}

