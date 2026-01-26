codeunit 144006 "UT REP Apply GL Entries"
{
    // Test for feature APPLGLENTR - Apply GL Entries.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        CapitalLetterTxt: Label 'AAA';
        SmallLetterTxt: Label 'aaa';

    [Test]
    [HandlerFunctions('GLAccountStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EvaluationDateNotAppliedCapitalGLAccountStmt()
    var
        GLEntries: Option All,Applied,"Not Applied";
    begin
        // Purpose of the test is to validate G/L Entry - OnAfterGetRecord Trigger of Report - 10842 G/L Account Statement.

        // Evaluation Date as WORKDATE and GL Entry Type as Not Applied for report G/L Account Statement. Letter for first and second GL Entry.
        EvaluationDateEntryTypeLetterGLAccountStmt(WorkDate(), GLEntries::"Not Applied", CapitalLetterTxt, SmallLetterTxt);
    end;

    [Test]
    [HandlerFunctions('GLAccountStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BlankEvaluationDateNotAppliedCapitalGLAccountStmt()
    var
        GLEntries: Option All,Applied,"Not Applied";
    begin
        // Purpose of the test is to validate G/L Entry - OnAfterGetRecord Trigger of Report - 10842 G/L Account Statement.

        // Evaluation Date as blank and GL Entry Type as Not Applied for report G/L Account Statement. Letter for first and second GL Entry.
        EvaluationDateEntryTypeLetterGLAccountStmt(0D, GLEntries::"Not Applied", CapitalLetterTxt, SmallLetterTxt);
    end;

    [Test]
    [HandlerFunctions('GLAccountStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EvaluationDateAppliedSmallGLAccountStmt()
    var
        GLEntries: Option All,Applied,"Not Applied";
    begin
        // Purpose of the test is to validate G/L Entry - OnAfterGetRecord Trigger of Report - 10842 G/L Account Statement.

        // Evaluation Date as WORKDATE and GL Entry Type as Applied for report G/L Account Statement. Letter for first and second GL Entry.
        EvaluationDateEntryTypeLetterGLAccountStmt(WorkDate(), GLEntries::Applied, SmallLetterTxt, CapitalLetterTxt);
    end;

    [Test]
    [HandlerFunctions('GLAccountStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BlankEvaluationDateAppliedSmallGLAccountStmt()
    var
        GLEntries: Option All,Applied,"Not Applied";
    begin
        // Purpose of the test is to validate G/L Entry - OnAfterGetRecord Trigger of Report - 10842 G/L Account Statement.

        // Evaluation Date as blank and GL Entry Type as Applied for report G/L Account Statement. Letter for first and second GL Entry.
        EvaluationDateEntryTypeLetterGLAccountStmt(0D, GLEntries::Applied, SmallLetterTxt, CapitalLetterTxt);
    end;

    local procedure EvaluationDateEntryTypeLetterGLAccountStmt(EvaluationDate: Date; GLEntries: Option; Letter: Text[3]; Letter2: Text[3])
    var
        GLEntry: Record "G/L Entry";
    begin
        // Setup: Create two GL Entry with different Letter and Posting Date.
        Initialize();
        CreateGLEntry(GLEntry, CreateGLAccount(), Letter, 0D);  // Using Posting Date as blank.
        CreateGLEntry(GLEntry, GLEntry."G/L Account No.", Letter2, WorkDate()); // Using Posting Date as WORKDATE.

        // Enqueue values in handler - GLAccountStatementRequestPageHandler.
        LibraryVariableStorage.Enqueue(GLEntry."G/L Account No.");
        LibraryVariableStorage.Enqueue(EvaluationDate);
        LibraryVariableStorage.Enqueue(GLEntries);

        // Exercise.
        REPORT.Run(REPORT::"G/L Account Statement");  // Opens handler - GLAccountStatementRequestPageHandler.

        // Verify: Verify G/L Account Number, G/L Entry Number, Debit Amount and Letter on Report - G/L Account Statement.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_GLAcc', GLEntry."G/L Account No.");
        LibraryReportDataset.AssertElementWithValueExists('EntryNo_GLEntry', GLEntry."Entry No.");
        LibraryReportDataset.AssertElementWithValueExists('DebitAmount_GLAcc', GLEntry."Debit Amount");
        LibraryReportDataset.AssertElementWithValueExists('Letter_GLEntry', Letter2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GLAccountStatementToExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GLAccountStatementSaveToExcel()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 332702] Run report "G/L Account Statement" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] G/L Entry.
        CreateGLEntry(GLEntry, CreateGLAccount(), SmallLetterTxt, WorkDate());

        // [WHEN] Run report "Withdraw recapitulation", save report output to Excel file.
        GLEntry.SetRecFilter();
        REPORT.Run(REPORT::"G/L Account Statement", true, false, GLEntry);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 9, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('G/L balance justification'), '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; Letter: Text[3]; PostingDate: Date)
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Debit Amount" := LibraryRandom.RandDec(10, 2);
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Letter := Letter;
        GLEntry."Letter Date" := GLEntry."Posting Date";
        GLEntry.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountStatementRequestPageHandler(var GLAccountStatement: TestRequestPage "G/L Account Statement")
    var
        EvaluationDate: Variant;
        GLEntries: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(EvaluationDate);
        LibraryVariableStorage.Dequeue(GLEntries);
        GLAccountStatement."G/L Account".SetFilter("No.", No);
        GLAccountStatement.EvaluationDate.SetValue(EvaluationDate);
        GLAccountStatement.GLEntries.SetValue(GLEntries);
        GLAccountStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountStatementToExcelRequestPageHandler(var GLAccountStatement: TestRequestPage "G/L Account Statement")
    begin
        GLAccountStatement.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

