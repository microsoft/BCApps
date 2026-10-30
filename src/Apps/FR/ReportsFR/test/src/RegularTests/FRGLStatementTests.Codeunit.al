// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Review;
using System.IO;
using System.Utilities;

codeunit 148011 "FR GL Statement Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Statement: Report "G/L Account Statement FR";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
#if not CLEAN30
        FeatureState: Codeunit "Library - Reports FR";
#endif
        Dataset: XmlDocument;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualityBoundaryIsAppliedOnly()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A fully applied letter dated on the evaluation date belongs only to Applied.
        Initialize();

        // [GIVEN] E has a full letter dated exactly at evaluation.
        GLEntry."Posting Date" := 20260115D;
        GLEntry.Letter := 'AAA';
        GLEntry."Letter Date" := 20260131D;

        // [WHEN] Both complementary application selections are evaluated.
        // [THEN] E is Applied and is not Not Applied.
        Assert.IsTrue(Statement.IncludeByApplicationStatus(GLEntry, 1, 20260131D), 'Equality must be applied.');
        Assert.IsFalse(Statement.IncludeByApplicationStatus(GLEntry, 2, 20260131D), 'Equality must not overlap.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FutureLetterIsNotAppliedAtEvaluation()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A future application date does not make an entry applied historically.
        Initialize();

        // [GIVEN] E has a full letter dated after evaluation.
        GLEntry."Posting Date" := 20260115D;
        GLEntry.Letter := 'AAA';
        GLEntry."Letter Date" := 20260201D;

        // [WHEN] Historical application state is evaluated.
        // [THEN] The full letter is ignored only for the earlier evaluation.
        Assert.IsFalse(Statement.IncludeByApplicationStatus(GLEntry, 1, 20260131D), 'Future application is excluded.');
        Assert.IsTrue(Statement.IncludeByApplicationStatus(GLEntry, 2, 20260131D), 'Historical Not Applied includes it.');
        Assert.IsTrue(Statement.IncludeByApplicationStatus(GLEntry, 1, 0D), 'Without evaluation use current application.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PartialAndBlankLettersAreNotApplied()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Reviewing is not application and lowercase or blank letters are not full application.
        Initialize();

        // [GIVEN] E is reviewed but its legacy letter is partial.
        GLEntry.Letter := 'aaa';
        GLEntry."Reviewed Date" := CreateDateTime(20260115D, 120000T);

        // [WHEN] Application is tested before and after clearing the letter.
        // [THEN] Neither state fabricates a full application from review state.
        Assert.IsFalse(Statement.IncludeByApplicationStatus(GLEntry, 1, 0D), 'Partial letters are not applied.');
        GLEntry.Letter := '';
        Assert.IsFalse(Statement.IncludeByApplicationStatus(GLEntry, 1, 0D), 'Review cannot supply a letter.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllApplicationReviewCombinationsIntersect()
    var
        GLAccount: Record "G/L Account";
        Entries: array[5] of Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] All nine application/review combinations filter actual report entry identities.
        Initialize();

        // [GIVEN] E1 is applied/reviewed, E2 and E3 not applied/not reviewed, E4 not applied/reviewed, E5 future.
        LibraryERM.CreateGLAccount(GLAccount);
        Entries[1] := CreateEntry(GLAccount."No.", 20260115D, 100, 0, 'AAA', 20260131D, 20260131D);
        Entries[2] := CreateEntry(GLAccount."No.", 20260116D, 0, 40, 'aaa', 0D, 0D);
        Entries[3] := CreateEntry(GLAccount."No.", 20260117D, 20, 0, 'BBB', 20260201D, 20260201D);
        Entries[4] := CreateEntry(GLAccount."No.", 20260118D, 0, 50, '', 0D, 20260130D);
        Entries[5] := CreateEntry(GLAccount."No.", 20260201D, 500, 0, '', 0D, 0D);

        // [WHEN] Every status pair is rendered into the report dataset.
        // [THEN] Inclusion is the intersection and future postings are always absent.
        VerifyAllStatusCombinations(GLAccount, Entries);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BalancesResetAndIncludedTotalsReconcile()
    var
        FirstAccount: Record "G/L Account";
        SecondAccount: Record "G/L Account";
        SelectedAccounts: Record "G/L Account";
        FirstDebitEntry: Integer;
        FirstCreditEntry: Integer;
        SecondDebitEntry: Integer;
        SecondCreditEntry: Integer;
        ExcludedEntry: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Running balances reset per account and totals include no excluded entries.
        Initialize();

        // [GIVEN] A has 100/40, B has 20/50, and a future entry is excluded.
        LibraryERM.CreateGLAccount(FirstAccount);
        LibraryERM.CreateGLAccount(SecondAccount);
        FirstDebitEntry := CreateEntry(FirstAccount."No.", 20260115D, 100, 0, '', 0D, 0D);
        FirstCreditEntry := CreateEntry(FirstAccount."No.", 20260116D, 0, 40, '', 0D, 0D);
        SecondDebitEntry := CreateEntry(SecondAccount."No.", 20260115D, 20, 0, '', 0D, 0D);
        SecondCreditEntry := CreateEntry(SecondAccount."No.", 20260116D, 0, 50, '', 0D, 0D);
        ExcludedEntry := CreateEntry(SecondAccount."No.", 20260201D, 500, 0, '', 0D, 0D);
        SelectedAccounts.SetFilter("No.", '%1|%2', FirstAccount."No.", SecondAccount."No.");

        // [WHEN] Both accounts are reported as of January.
        LoadDataset(SelectedAccounts, 0, 0, 20260131D);

        // [THEN] Running balances are independent and included movements reconcile.
        VerifyRunningBalance(FirstDebitEntry, 100);
        VerifyRunningBalance(FirstCreditEntry, 60);
        VerifyRunningBalance(SecondDebitEntry, 20);
        VerifyRunningBalance(SecondCreditEntry, -30);
        VerifyEntryPresence(ExcludedEntry, false);
        Assert.AreEqual(120, SumDetailValues('DebitAmount_GLEntry'), 'Included debits must reconcile.');
        Assert.AreEqual(90, SumDetailValues('CreditAmount_GLEntry'), 'Included credits must reconcile.');
        VerifyFinalTotal('TotalDebit', 120);
        VerifyFinalTotal('TotalCredit', 90);
        VerifyFinalTotal('TotalBalance', 30);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatementRendersPdf()
    var
        GLAccount: Record "G/L Account";
        TempBlob: Codeunit "Temp Blob";
        Artifacts: Codeunit "FR Financial Integration Tests";
        Output: OutStream;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The extracted statement layout renders through the supported PDF export.
        Initialize();

        // [GIVEN] A has one included entry.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20260115D, 100, 0, 'AAA', 20260131D, 0D);
        GLAccount.SetRecFilter();
        Statement.SetTableView(GLAccount);
        Statement.SetOptions(0, 0, 20260131D);
        TempBlob.CreateOutStream(Output);

        // [WHEN] The RDLC renderer exports the report.
        Statement.SaveAs('', ReportFormat::Pdf, Output);

        // [THEN] Rendering has produced a nonempty PDF, independently of dataset assertions.
        Assert.IsTrue(TempBlob.HasValue(), 'The statement must render a PDF.');
        Artifacts.SaveArtifact('653672-Statement.pdf', TempBlob);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenderedStatementReconcilesIncludedMovements()
    var
        GLAccount: Record "G/L Account";
        TempCells: Record "Excel Buffer" temporary;
        Data: Codeunit "Temp Blob";
        Rendered: Codeunit "FR Financial Integration Tests";
        Output: OutStream;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The RDLC Excel renderer shows the included movements, balance and totals.
        Initialize();

        // [GIVEN] A has debit 100, credit 40 and a future excluded debit.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20260115D, 100, 0, '', 0D, 0D);
        CreateEntry(GLAccount."No.", 20260116D, 0, 40, '', 0D, 0D);
        CreateEntry(GLAccount."No.", 20260201D, 500, 0, '', 0D, 0D);
        GLAccount.SetRecFilter();
        Statement.SetTableView(GLAccount);
        Statement.SetOptions(0, 0, 20260131D);
        Data.CreateOutStream(Output);

        // [WHEN] The report is rendered to an actual Excel workbook.
        Statement.SaveAs('', ReportFormat::Excel, Output);
        Rendered.ReadRenderedExcel(Data, TempCells);

        // [THEN] Rendered content, rather than just dataset values, reconciles.
        Rendered.VerifyRenderedText(TempCells, 'G/L balance justification');
        Rendered.VerifyRenderedNumber(TempCells, 100);
        Rendered.VerifyRenderedNumber(TempCells, 40);
        Rendered.VerifyRenderedNumber(TempCells, 60);
        Rendered.SaveArtifact('653672-Statement.xlsx', Data);
    end;

    local procedure Initialize()
    var
        Migration: Codeunit "Library - Reports FR";
    begin
        Clear(Statement);
#if not CLEAN30
        Clear(FeatureState);
        FeatureState.SetFeatureEnabled(true);
        BindSubscription(FeatureState);
#endif
        Migration.Migrate();
    end;

    local procedure CreateEntry(AccountNo: Code[20]; PostingDate: Date; Debit: Decimal; Credit: Decimal; Letter: Text[3]; LetterDate: Date; ReviewedDate: Date): Integer
    var
        GLEntry: Record "G/L Entry";
        ReviewLog: Record "G/L Entry Review Log";
        NextEntryNo: Integer;
    begin
        if GLEntry.FindLast() then
            NextEntryNo := GLEntry."Entry No." + 1
        else
            NextEntryNo := 1;
        GLEntry.Init();
        GLEntry."Entry No." := NextEntryNo;
        GLEntry."G/L Account No." := AccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry."Debit Amount" := Debit;
        GLEntry."Credit Amount" := Credit;
        GLEntry.Amount := Debit - Credit;
        GLEntry.Letter := Letter;
        GLEntry."Letter Date" := LetterDate;
        GLEntry.Insert(false);
        if ReviewedDate <> 0D then begin
            ReviewLog."G/L Entry No." := GLEntry."Entry No.";
            ReviewLog."G/L Account No." := AccountNo;
            ReviewLog."Reviewed At" := CreateDateTime(ReviewedDate, 120000T);
            ReviewLog."Reviewed Amount" := Debit - Credit;
            ReviewLog.Insert(true);
        end;
        exit(GLEntry."Entry No.");
    end;

    local procedure LoadDataset(GLAccount: Record "G/L Account"; ApplicationStatus: Integer; ReviewStatus: Integer; EvaluationDate: Date)
    var
        TempBlob: Codeunit "Temp Blob";
        Output: OutStream;
        Input: InStream;
    begin
        Clear(Statement);
        Statement.SetTableView(GLAccount);
        Statement.SetOptions(ApplicationStatus, ReviewStatus, EvaluationDate);
        TempBlob.CreateOutStream(Output);
        Statement.SaveAs('', ReportFormat::Xml, Output);
        TempBlob.CreateInStream(Input);
        XmlDocument.ReadFrom(Input, Dataset);
    end;

    local procedure VerifyAllStatusCombinations(GLAccount: Record "G/L Account"; Entries: array[5] of Integer)
    var
        ApplicationStatus: Integer;
        ReviewStatus: Integer;
        EntryIndex: Integer;
        Expected: Boolean;
    begin
        GLAccount.SetRecFilter();
        for ApplicationStatus := 0 to 2 do
            for ReviewStatus := 0 to 2 do begin
                LoadDataset(GLAccount, ApplicationStatus, ReviewStatus, 20260131D);
                for EntryIndex := 1 to 4 do begin
                    Expected :=
                        ((ApplicationStatus = 0) or ((ApplicationStatus = 1) and (EntryIndex = 1)) or
                         ((ApplicationStatus = 2) and (EntryIndex <> 1))) and
                        ((ReviewStatus = 0) or ((ReviewStatus = 1) and (EntryIndex in [1, 4])) or
                         ((ReviewStatus = 2) and (EntryIndex in [2, 3])));
                    VerifyEntryPresence(Entries[EntryIndex], Expected);
                end;
                VerifyEntryPresence(Entries[5], false);
                if (ApplicationStatus = 1) and (ReviewStatus = 2) then
                    VerifyNoIncludedTotals();
            end;
    end;

    local procedure VerifyRunningBalance(EntryNo: Integer; ExpectedBalance: Decimal)
    var
        EntryNode: XmlNode;
        ValueNode: XmlNode;
    begin
        Assert.IsTrue(
            Dataset.SelectSingleNode(
                '//*[local-name()="Column" and @name="EntryNo_GLEntry" and text()="' + Format(EntryNo, 0, 9) + '"]/..', EntryNode),
            'The included entry must have its own dataset row.');
        Assert.IsTrue(EntryNode.SelectSingleNode('*[local-name()="Column" and @name="Balance_GLEntry"]', ValueNode), 'The entry must expose its balance.');
        Assert.AreEqual(ExpectedBalance, DecimalValue(ValueNode), 'Running balance must be correlated with its entry.');
    end;

    local procedure VerifyEntryPresence(EntryNo: Integer; Expected: Boolean)
    var
        EntryNodes: XmlNodeList;
    begin
        Dataset.SelectNodes(
            '//*[local-name()="Column" and @name="EntryNo_GLEntry" and text()="' + Format(EntryNo, 0, 9) + '"]', EntryNodes);
        if Expected then
            Assert.AreEqual(1, EntryNodes.Count(), 'An included entry must occur exactly once.')
        else
            Assert.AreEqual(0, EntryNodes.Count(), 'An excluded entry must not occur anywhere in the XML.');
    end;

    local procedure SumDetailValues(ElementName: Text) Total: Decimal
    var
        ValueNodes: XmlNodeList;
        ValueNode: XmlNode;
    begin
        Dataset.SelectNodes('//*[local-name()="Column" and @name="' + ElementName + '"]', ValueNodes);
        foreach ValueNode in ValueNodes do
            Total += DecimalValue(ValueNode);
    end;

    local procedure VerifyFinalTotal(ElementName: Text; Expected: Decimal)
    var
        ValueNodes: XmlNodeList;
        ValueNode: XmlNode;
    begin
        Dataset.SelectNodes('//*[local-name()="Column" and @name="' + ElementName + '"]', ValueNodes);
        Assert.IsTrue(ValueNodes.Count() > 0, 'The dataset must emit included-entry totals.');
        ValueNodes.Get(ValueNodes.Count(), ValueNode);
        Assert.AreEqual(Expected, DecimalValue(ValueNode), 'The final emitted total must reconcile to all included details.');
    end;

    local procedure VerifyNoIncludedTotals()
    var
        ValueNodes: XmlNodeList;
    begin
        Dataset.SelectNodes(
            '//*[local-name()="Column" and (@name="TotalDebit" or @name="TotalCredit" or @name="TotalBalance") and number(text()) != 0]',
            ValueNodes);
        Assert.AreEqual(0, ValueNodes.Count(), 'An all-filtered statement must not emit nonzero included-entry totals.');
    end;

    local procedure DecimalValue(ValueNode: XmlNode) Value: Decimal
    begin
        Evaluate(Value, ValueNode.AsXmlElement().InnerText(), 9);
    end;
}
