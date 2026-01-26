codeunit 144072 "UT REP Fiscal Year"
{
    //   1-3. Purpose of these test cases to verify different error messages on OnPreDataItem Date Trigger for Report 10800 (G/L Journal).
    //   4-5. Purpose of these test cases to verify different error messages on OnPreDataItem GL Account trigger for Report 10803 (G/L Trial Balance).
    //   6-9. Purpose of these test cases to verify different error message on OnPreDataItem GL Account trigger for Report 10804 (G/L Detail Trial Balance).
    // 10-16. Purpose of these test cases to verify different error message on OnPreDataItemDate trigger for Report 10801 (Journals).
    // 
    // Covers Test Cases for WI - 344855
    // ---------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                                                      TFS ID
    // ---------------------------------------------------------------------------------------------------------------------------------------------------------------
    // OnPreDataItemDateGLJournalPeriodStartFieldBlankErr, OnPreDataItemDateGLJournalSpecifyPeriodStartErr, OnPreDataItemDateGLJournalPeriodStartFirstDayErr   151794
    // OnPreDataItemGLAccGLTrialBalanceDateFilterErr, OnPreDataItemGLAccGLTrialBalanceStartDateErr                                                             151796
    // OnPreDataItemGLAccGLDetailTrialBalanceDateFilterErr, OnPreDataItemGLAccGLDetailTrialBalanceStartDateErr                                                 151797
    // OnPreDataItemGLAccGLDetailTrialBalanceWrongStartDateErr, OnPreDataItemGLAccGLDetailTrialBalanceEndDateErr                                               151797
    // OnPreDataItemDateJournalsPeriodStartFieldBlankErr, OnPreDataItemDateJournalsSpecifyPeriodStartErr, OnPreDataItemDateJournalsPeriodStartDateErr          151795
    // OnPreDataItemDateJournalsPeriodEndDateErr, OnValidatePostingDateJournalsDocumentNoErr,OnValidatePostingDateJournalsPostingDateErr                       151795
    // OnPreDataItemDateJournalsPeriodTypeFieldBlankErr                                                                                                        151795

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DialogTxt: Label 'Dialog';
        PeriodStartFilterTxt: Label '%1..%2';
        TestValidationTxt: Label 'TestValidation';
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('GLJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateGLJournalPeriodStartFieldBlankErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10800 (G/L Journal).
        // Actual Error message is: You must fill in the Period Start field.
        LocalGLReportErrors(REPORT::"G/L Journal", '', DialogTxt);  // Use Blank Period Start Date.
    end;

    [Test]
    [HandlerFunctions('GLJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateGLJournalSpecifyPeriodStartErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10800 (G/L Journal).
        // Actual Error message is: You must specify a Starting Date.
        LocalGLReportErrors(REPORT::"G/L Journal", StrSubstNo(PeriodStartFilterTxt, '', WorkDate()), DialogTxt);  // Use first parameter as Blank for Period Start.
    end;

    [Test]
    [HandlerFunctions('GLJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateGLJournalPeriodStartFirstDayErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10800 (G/L Journal).
        // Actual Error message is: The starting date must be the first day of a month.
        LocalGLReportErrors(
          REPORT::"G/L Journal", StrSubstNo(PeriodStartFilterTxt, CalcDate('<1D>', CalcDate('<-CM>', WorkDate())), WorkDate()), DialogTxt);  // Use a Date that is not a Starting Date of month.
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccGLTrialBalanceDateFilterErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItem GL Account trigger for Report 10803 (G/L Trial Balance).
        // Actual error message: You must fill in the Date Filter field.
        LocalGLReportErrors(REPORT::"G/L Trial Balance", '', DialogTxt);  // Use Blank for Date Filter Field.
    end;

    [Test]
    [HandlerFunctions('GLTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccGLTrialBalanceStartDateErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItem GL Account trigger for Report 10803 (G/L Trial Balance).
        // Actual error message: You must specify a Starting Date.
        LocalGLReportErrors(REPORT::"G/L Trial Balance", StrSubstNo(PeriodStartFilterTxt, '', WorkDate()), DialogTxt);  // Use first parameter as Blank for Date Filter field.
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccGLDetailTrialBalanceDateFilterErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItem GL Account trigger for Report 10804 (G/L Detail Trial Balance).
        // Actual error message: You must fill in the Date Filter field.
        LocalGLReportErrors(REPORT::"G/L Detail Trial Balance", '', DialogTxt);  // Use first parameter as Blank for Date Filter field.
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccGLDetailTrialBalanceStartDateErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItem GL Account trigger for Report 10804 (G/L Detail Trial Balance).
        // Actual error message: You must specify a Starting Date.
        LocalGLReportErrors(REPORT::"G/L Detail Trial Balance", StrSubstNo(PeriodStartFilterTxt, '', WorkDate()), DialogTxt);  // Use first parameter as Blank for Date Filter field.
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccGLDetailTrialBalanceWrongStartDateErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItem GL Account trigger for Report 10804 (G/L Detail Trial Balance).
        // Actual error message: The selected starting date XXXXXX is not the start of a Month.
        LocalGLReportErrors(
          REPORT::"G/L Detail Trial Balance", StrSubstNo(PeriodStartFilterTxt, CalcDate('<1D>', CalcDate('<-CM>', WorkDate())), WorkDate()),
          DialogTxt);  // Use a Date that is not a Starting Date of month.
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGLAccGLDetailTrialBalanceEndDateErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItem GL Account trigger for Report 10804 (G/L Detail Trial Balance).
        // Actual error message: The selected ending date XXXXXX is not the end of a Month.
        LocalGLReportErrors(
          REPORT::"G/L Detail Trial Balance",
          StrSubstNo(PeriodStartFilterTxt, CalcDate('<-CM>', WorkDate()), CalcDate('<-1D>', CalcDate('<CM>', WorkDate()))), DialogTxt);  // Use a Date that is not a Starting Date of month.
    end;

    [Test]
    [HandlerFunctions('JournalsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateJournalsPeriodStartFieldBlankErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10801 (Journals).
        // Actual error message: You must fill in the Period Start field.
        LocalGLReportErrors(REPORT::Journals, '', DialogTxt);  // Use Blank Period Start Date.
    end;

    [Test]
    [HandlerFunctions('JournalsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateJournalsSpecifyPeriodStartErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10801 (Journals).
        // Actual error message: You must specify a Starting Date.
        LocalGLReportErrors(REPORT::Journals, StrSubstNo(PeriodStartFilterTxt, '', WorkDate()), DialogTxt);  // Use first parameter as Blank for Period Start.
    end;

    [Test]
    [HandlerFunctions('JournalsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateJournalsPeriodStartDateErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10801 (Journals).
        // Actual error message: The selected starting date XXXXXX is not the start of a Month.
        LocalGLReportErrors(
          REPORT::Journals, StrSubstNo(PeriodStartFilterTxt, CalcDate('<1D>', CalcDate('<-CW>', WorkDate())), WorkDate()), DialogTxt);  // Use a Date that is not a Starting Date of month.
    end;

    [Test]
    [HandlerFunctions('WrongEndDateJournalsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateJournalsPeriodEndDateErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10801 (Journals).
        // Actual error message: The selected ending date XXXXXX is not the end of a Month.
        LocalGLReportErrors(
          REPORT::Journals, StrSubstNo(PeriodStartFilterTxt, CalcDate('<-1D>', CalcDate('<CM>', WorkDate())), WorkDate()), DialogTxt);  // Period End;
    end;

    [Test]
    [HandlerFunctions('CentralizeJournalsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePostingDateJournalsDocumentNoErr()
    var
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to verify error message on OnValidate Posting Date trigger for Report 10801 (Journals).
        // Actual error message: Validation error for Field:Posting Date,  Message = 'Document No. is not a valid selection.'
        LocalGLReportErrors(REPORT::Journals, SortingBy::"Document No.", TestValidationTxt);
    end;

    [Test]
    [HandlerFunctions('CentralizeJournalsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePostingDateJournalsPostingDateErr()
    var
        SortingBy: Option "Posting Date","Document No.";
    begin
        // Purpose of the test is to verify error message on OnValidate Posting Date trigger for Report 10801 (Journals).
        // Actual error message: Validation error for Field:Posting Date,  Message = 'Posting Date is not a valid selection.'
        LocalGLReportErrors(REPORT::Journals, SortingBy::"Posting Date", TestValidationTxt);
    end;

    [Test]
    [HandlerFunctions('NoFilterOnJournalsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemDateJournalsPeriodTypeFieldBlankErr()
    begin
        // Purpose of the test is to verify error message on OnPreDataItemDate trigger for Report 10801 (Journals).

        // Setup.
        Initialize();

        // Exercise: Try to execute report without any filter.
        asserterror REPORT.Run(REPORT::Journals);  // Invokes NoFilterOnJournalsRequestPageHandler.

        // Verify: Actual error message: You must fill in the Period Type field.
        Assert.ExpectedErrorCode(DialogTxt);
    end;

    [Test]
    [HandlerFunctions('GLJournalRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLReportWithOneDateInPeriodStart()
    begin
        // [FEATURE] [G/L Journal Report] [UT]
        // [SCENARIO 375111] If one date is specified in Period Start filter of "G/L Journal" report (10800) instead of period - error message should appear
        LocalGLReportErrors(REPORT::"G/L Journal", Format(CalcDate('<-CY>', WorkDate())), DialogTxt);
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceForGLAccountNoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLDetailTrialBalanceForMultipleGLAccounts()
    var
        GLAccount: array[2] of Record "G/L Account";
        GLEntry: array[2] of Record "G/L Entry";
    begin
        // [SCENARIO 331475] Balance of one G/L Account doesn't affect another.
        Initialize();

        // [GIVEN] Two G/L Accounts with Entries for Amount 100 and 333 respectively.
        LibraryERM.CreateGLAccount(GLAccount[1]);
        CreateGLEntry(GLEntry[1], GLAccount[1]."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateGLEntry(GLEntry[2], GLAccount[2]."No.", LibraryRandom.RandDec(10, 2), WorkDate());

        // [WHEN] Report "G/L Detail Trial Balance" is run for these accounts.
        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', GLAccount[1]."No.", GLAccount[2]."No."));
        LibraryVariableStorage.Enqueue(
          StrSubstNo(PeriodStartFilterTxt, CalcDate('<-CM>', GLEntry[2]."Posting Date"), CalcDate('<+CM>', GLEntry[2]."Posting Date")));
        Commit();
        REPORT.Run(REPORT::"G/L Detail Trial Balance", true);

        // [THEN] Resulting dataset have 'Balance' = 100 and 'Balance' = 333.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Balance', GLEntry[1].Amount);
        LibraryReportDataset.AssertElementWithValueExists('Balance', GLEntry[2].Amount);
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceForGLAccountNoRequestPageHandler')]
    procedure GLDetailTrialBalanceForMultipleGLAccountsWithClosingDateEntries_Exclude()
    var
        GLAccount: array[2] of Record "G/L Account";
        GLEntry: array[3] of Record "G/L Entry";
        PostingDate: Date;
    begin
        // [FEATURE] [Closing Date]
        // [SCENARIO 383626] Balance of a G/L Account doesn't include G/L Entry with posting date at Closing Date when date filter ends with Normal Date
        Initialize();

        PostingDate := CalcDate('<CM>', WorkDate());

        LibraryERM.CreateGLAccount(GLAccount[1]);
        CreateGLEntry(GLEntry[1], GLAccount[1]."No.", LibraryRandom.RandDecInRange(10, 100, 2), PostingDate);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateGLEntry(GLEntry[2], GLAccount[2]."No.", LibraryRandom.RandDecInRange(10, 100, 2), PostingDate);
        CreateGLEntry(GLEntry[3], GLAccount[2]."No.", LibraryRandom.RandDecInRange(10, 100, 2), ClosingDate(PostingDate));

        // [WHEN] Report "G/L Detail Trial Balance" is run for these accounts.
        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', GLAccount[1]."No.", GLAccount[2]."No."));
        LibraryVariableStorage.Enqueue(StrSubstNo(PeriodStartFilterTxt, CalcDate('<-CM>', PostingDate), PostingDate));
        Commit();
        REPORT.Run(REPORT::"G/L Detail Trial Balance", true);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Balance', GLEntry[1].Amount);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Balance', GLEntry[2].Amount);
        Assert.AreEqual(2, LibraryReportDataset.RowCount(), '');
    end;

    [Test]
    [HandlerFunctions('GLDetailTrialBalanceForGLAccountNoRequestPageHandler')]
    procedure GLDetailTrialBalanceForMultipleGLAccountsWithClosingDateEntries_Include()
    var
        GLAccount: array[2] of Record "G/L Account";
        GLEntry: array[3] of Record "G/L Entry";
        PostingDate: Date;
    begin
        // [FEATURE] [Closing Date]
        // [SCENARIO 383626] Balance of a G/L Account includes G/L Entry with posting date at Closing Date when date filter ends with Closing Date
        Initialize();

        PostingDate := CalcDate('<CM>', WorkDate());

        LibraryERM.CreateGLAccount(GLAccount[1]);
        CreateGLEntry(GLEntry[1], GLAccount[1]."No.", LibraryRandom.RandDecInRange(10, 100, 2), PostingDate);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        CreateGLEntry(GLEntry[2], GLAccount[2]."No.", LibraryRandom.RandDecInRange(10, 100, 2), PostingDate);
        CreateGLEntry(GLEntry[3], GLAccount[2]."No.", LibraryRandom.RandDecInRange(10, 100, 2), ClosingDate(PostingDate));

        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', GLAccount[1]."No.", GLAccount[2]."No."));
        LibraryVariableStorage.Enqueue(StrSubstNo(PeriodStartFilterTxt, CalcDate('<-CM>', PostingDate), ClosingDate(PostingDate)));
        Commit();
        REPORT.Run(REPORT::"G/L Detail Trial Balance", true);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Balance', GLEntry[1].Amount);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Balance', GLEntry[2].Amount);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Balance', GLEntry[2].Amount + GLEntry[3].Amount);
        Assert.AreEqual(3, LibraryReportDataset.RowCount(), '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; DebitAmount: Decimal; PostingDate: Date)
    begin
        if GLEntry.FindLast() then
            GLEntry.Init();
        GLEntry."Entry No." += 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry.Amount := DebitAmount;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Insert();
    end;

    local procedure LocalGLReportErrors(ReportID: Integer; PeriodStart: Variant; ErrorCode: Text)
    begin
        // Setup: Enqueue value for GLJournalRequestPageHandler, GLTrialBalanceRequestPageHandler, GLDetailTrialBalanceRequestPageHandler.
        Initialize();
        LibraryVariableStorage.Enqueue(PeriodStart);

        // Exercise: Invokes CentralizeJournalsRequestPageHandler, GLDetailTrialBalanceRequestPageHandler, GLJournalRequestPageHandler,
        // GLTrialBalanceRequestPageHandler, JournalsRequestPageHandler, WrongEndDateJournalsRequestPageHandler.
        asserterror REPORT.Run(ReportID);

        // Verify.
        Assert.ExpectedErrorCode(ErrorCode);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CentralizeJournalsRequestPageHandler(var Journals: TestRequestPage Journals)
    var
        Date: Record Date;
        PostingDate: Variant;
        Display: Option Journals,"Centralized Journals","Journals and Centralization";
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        Journals.Journals.SetValue(Display::"Centralized Journals");
        Journals."Posting Date".SetValue(PostingDate);
        Journals.Date.SetFilter("Period Type", Format(Date."Period Type"::Month));
        Journals.Date.SetFilter("Period Start", StrSubstNo(PeriodStartFilterTxt, CalcDate('<-CM>', WorkDate()), WorkDate()));  // Period Start.
        Journals.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLDetailTrialBalanceRequestPageHandler(var GLDetailTrialBalance: TestRequestPage "G/L Detail Trial Balance")
    var
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateFilter);
        GLDetailTrialBalance."G/L Account".SetFilter("Date Filter", DateFilter);
        GLDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLDetailTrialBalanceForGLAccountNoRequestPageHandler(var GLDetailTrialBalance: TestRequestPage "G/L Detail Trial Balance")
    var
        DateFilter: Variant;
    begin
        GLDetailTrialBalance."G/L Account".SetFilter("No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Dequeue(DateFilter);
        GLDetailTrialBalance."G/L Account".SetFilter("Date Filter", DateFilter);
        GLDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLJournalRequestPageHandler(var GLJournal: TestRequestPage "G/L Journal")
    var
        PeriodStart: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodStart);
        GLJournal.Date.SetFilter("Period Start", PeriodStart);
        GLJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLTrialBalanceRequestPageHandler(var GLTrialBalance: TestRequestPage "G/L Trial Balance")
    var
        DateFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateFilter);
        GLTrialBalance."G/L Account".SetFilter("Date Filter", DateFilter);
        GLTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JournalsRequestPageHandler(var Journals: TestRequestPage Journals)
    var
        Date: Record Date;
        PeriodStart: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodStart);
        Journals.Date.SetFilter("Period Type", Format(Date."Period Type"::Month));
        Journals.Date.SetFilter("Period Start", PeriodStart);
        Journals.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NoFilterOnJournalsRequestPageHandler(var Journals: TestRequestPage Journals)
    begin
        Journals.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WrongEndDateJournalsRequestPageHandler(var Journals: TestRequestPage Journals)
    var
        Date: Record Date;
        PeriodEnd: Variant;
    begin
        LibraryVariableStorage.Dequeue(PeriodEnd);
        Journals.Date.SetFilter("Period Type", Format(Date."Period Type"::Month));
        Journals.Date.SetFilter("Period Start", StrSubstNo(PeriodStartFilterTxt, CalcDate('<-CM>', WorkDate()), WorkDate()));
        Journals.Date.SetFilter("Period End", PeriodEnd);
        Journals.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

