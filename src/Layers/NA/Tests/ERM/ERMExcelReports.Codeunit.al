codeunit 134999 "ERM Excel Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Save As Excel]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        EvaluateErr: Label 'Value %1 cannot be converted to decimal.';
        IncorrectTotalBalanceLCYErr: Label 'Incorrect total balance LCY value.';
        CellValueNotFoundErr: Label 'Excel cell (row=%1, column=%2) value is not found.';
        TotalLCYCap: Label 'Total (%1)';
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        AmountMustBeSpecifiedTxt: Label 'Amount must be specified.';
        DefaultTxt: Label 'LCY';

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalTestTotalBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Total Balance printing by General Journal Test Report (bug 333253)

        // Setup.
        Initialize();
        Create2GenJnlLines(GenJournalLine);

        // Exercise: Save General Journal Test Report to Excel.
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // Verify: Verify Total Balance value
        VerifyGeneralJournalTestTotalBalance();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAmountWarningGeneralJournalTestEmptyGenPostingType()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [G/L Account] [Report]
        // [SCENARIO 361902] General Journal - Test report shows zero amount warning if posting type is blank in gen. journal and zero amount
        Initialize();

        // [GIVEN] G/L Account X with blank Gen. Posting Type
        CreateGLAccountWithPostingType(GLAccount, GLAccount."Gen. Posting Type"::" ");

        // [GIVEN] Gen. Journal Line with G/L Account X and 0 amount
        CreateGenJournalLine(GenJournalLine, GLAccount."No.", 0);

        // [WHEN] Run Report 2 General Journal - Test
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // [THEN] Report contains warning - Amount must be specified.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(21, 4, AmountMustBeSpecifiedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroAmountWarningGeneralJournalTestNotEmptyGenPostingType()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [G/L Account] [Report]
        // [SCENARIO 361902] General Journal - Test report shows zero amount warning if posting type is not blank in gen. journal and zero amount
        Initialize();

        // [GIVEN] G/L Account X with not blank Gen. Posting Type
        CreateGLAccountWithPostingType(GLAccount, GLAccount."Gen. Posting Type"::Purchase);

        // [GIVEN] Gen. Journal Line with G/L Account X and 0 amount
        CreateGenJournalLine(GenJournalLine, GLAccount."No.", 0);

        // [WHEN] Run Report 2 General Journal - Test
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // [THEN] Report contains warning - Amount must be specified.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(21, 4, AmountMustBeSpecifiedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJournalTestReportOnRecurringGenJnlLinesWithPercentInDocNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedDocNo: Code[20];
    begin
        // [FEATURE] [Recurring Journal] [Report]
        // [SCENARIO 309575] "General Journal - Test" report processes all recurring lines in current batch in case Document No. contains code like %1, %2 etc.
        Initialize();

        // [GIVEN] Two recurring General Journal Lines with Document No. = "%4 ABCD". %4 is substituted by month's name from Posting Date.
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalBatch, '%4 ' + LibraryUtility.GenerateGUID());
        CreateRecurringGenJnlLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document No.");
        ExpectedDocNo := StrSubstNo(GenJournalLine."Document No.", '', '', '', FORMAT(GenJournalLine."Posting Date", 0, '<Month Text>'));

        // [WHEN] Run Report "General Journal - Test".
        RunReportGeneralJournalTest(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // [THEN] Both lines are shown in the report results.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(20, 4, ExpectedDocNo);
        LibraryReportValidation.VerifyCellValue(21, 4, ExpectedDocNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Excel Reports");

        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Excel Reports");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Excel Reports");
    end;

    local procedure ClearGeneralJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure Create2GenJnlLines(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        ClearGeneralJournalLines(GenJournalBatch);
        Amount := LibraryRandom.RandDec(1000, 2);

        CreateGenJnlLine(GenJournalLine, GenJournalBatch, Amount);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, -Amount);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), Amount);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
    end;

    local procedure CreateRecurringGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        GenJournalTemplate.TestField(Recurring, true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccountWithPostingType(var GLAccount: Record "G/L Account"; PostingType: Enum "General Posting Type")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", PostingType);
        GLAccount.Modify(true);
    end;

    local procedure RunReportGeneralJournalTest(JournalTemplateName: Code[20]; JournalBatchName: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GeneralJournalTest: Report "General Journal - Test";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        GenJnlLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        GeneralJournalTest.SetTableView(GenJnlLine);
        GeneralJournalTest.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.DownloadFile();
    end;

    local procedure VerifyGeneralJournalTestTotalBalance()
    var
        RefGenJnlLine: Record "Gen. Journal Line";
        ValueFound: Boolean;
        TotalBalanceLCYAsText: Text;
        TotalBalanceLCY: Decimal;
        Row: Integer;
        Column: Integer;
    begin
        // Verify Saved Report's Data.
        LibraryReportValidation.OpenExcelFile();

        // Retrieve value from cell: row Total (LCY) and column Balance (LCY)
        Row := LibraryReportValidation.FindRowNoFromColumnCaption(FindColumnCaption());
        Column := LibraryReportValidation.FindColumnNoFromColumnCaption(RefGenJnlLine.FieldCaption("Balance (LCY)"));
        TotalBalanceLCYAsText := LibraryReportValidation.GetValueAt(ValueFound, Row, Column);
        Assert.IsTrue(ValueFound, StrSubstNo(CellValueNotFoundErr, Row, Column));
        Assert.IsTrue(
          Evaluate(TotalBalanceLCY, TotalBalanceLCYAsText),
          CopyStr(StrSubstNo(EvaluateErr, TotalBalanceLCYAsText), 1, 1024));
        Assert.AreEqual(0, TotalBalanceLCY, IncorrectTotalBalanceLCYErr);
    end;

    local procedure FindColumnCaption(): Text[250]
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencyResult: Text[30];
    begin
        // The following function copies functionality from cod342 (Currency CaptionClass Mgmt)
        if not GLSetup.Get() then
            exit(TotalLCYCap);

        if GLSetup."LCY Code" = '' then
            CurrencyResult := DefaultTxt
        else
            if not Currency.Get(GLSetup."LCY Code") then
                CurrencyResult := GLSetup."LCY Code"
            else
                CurrencyResult := Currency.Code;

        exit(CopyStr(StrSubstNo(TotalLCYCap, CurrencyResult), 1, 250));
    end;
}
