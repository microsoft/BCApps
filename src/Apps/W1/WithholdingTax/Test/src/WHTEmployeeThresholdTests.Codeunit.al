// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Tests.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.WithholdingTax;
using Microsoft.WithholdingTax.Employee;
using System.TestLibraries.Utilities;

codeunit 148323 "WHT Employee Threshold Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;

    trigger OnRun()
    begin
        // [FEATURE] [Withholding Tax] [Employee] [Threshold]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWithholdingTax: Codeunit "Library - Withholding Tax";
        IsInitialized: Boolean;
        WrongValueErr: Label 'Wrong value of %1.', Comment = '%1 = field or amount description';

    [Test]
    procedure TaxAboveThresholdEmployeeAccountFirst()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 657603] Employee journal line with a G/L balancing account withholds tax only on the amount above the period threshold.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [WHEN] Post 3,000 with the employee as the account and the G/L account as the balancing account.
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, GLAccountNo, true, 3000);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Withholding tax is 400 on the taxable base 2,000; the G/L account is credited with 2,600 and the period accumulates 3,000.
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine."Document No.", EmployeeNo, GLAccountNo, 3000, 400, 2000);
        VerifyAccumulatedBase(EmployeeNo, 3000);
    end;

    [Test]
    procedure TaxAboveThresholdGLAccountFirst()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 657603] G/L journal line with an employee balancing account withholds tax only on the amount above the period threshold.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [WHEN] Post 3,000 with the G/L account as the account and the employee as the balancing account.
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, GLAccountNo, false, 3000);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Withholding tax is 400 on the taxable base 2,000; the G/L account is credited with 2,600 and the period accumulates 3,000.
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine."Document No.", EmployeeNo, GLAccountNo, 3000, 400, 2000);
        VerifyAccumulatedBase(EmployeeNo, 3000);
    end;

    [Test]
    procedure TaxAboveThresholdConsecutiveTransactions()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 657603] Once the period threshold is exceeded, the next transaction is taxed in full.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] 3,000 posted with the employee as the account.
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, GLAccountNo, true, 3000);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [WHEN] Post 600 with the G/L account as the account.
        CreateEmployeeJournalLine(GenJournalLine[2], WHTPostingSetup, EmployeeNo, GLAccountNo, false, 600);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        // [THEN] The first transaction withholds 400 on 2,000; the second withholds 120 on the full 600.
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine[1]."Document No.", EmployeeNo, GLAccountNo, 3000, 400, 2000);
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine[2]."Document No.", EmployeeNo, GLAccountNo, 600, 120, 600);

        // [THEN] The period accumulates the original bases 3,000 + 600.
        VerifyAccumulatedBase(EmployeeNo, 3600);
    end;

    [Test]
    procedure TotalPeriodThresholdGLAccountFirstOptionDisabled()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 657603] With a G/L account posted before the employee balancing account, the current base is not subtracted from the period total.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" disabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", false);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] 500 posted in the period, below the threshold.
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, GLAccountNo, false, 500);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [WHEN] Post 600 with the G/L account as the account and the employee as the balancing account.
        CreateEmployeeJournalLine(GenJournalLine[2], WHTPostingSetup, EmployeeNo, GLAccountNo, false, 600);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        // [THEN] No tax for the first transaction; the second withholds 120 on 600 on both the employee and the G/L side.
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine[1]."Document No.", EmployeeNo, GLAccountNo, 500, 0, 500);
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine[2]."Document No.", EmployeeNo, GLAccountNo, 600, 120, 600);
        VerifyAccumulatedBase(EmployeeNo, 1100);
    end;

    [Test]
    procedure TotalPeriodThresholdEmployeeAccountFirstOptionDisabled()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 657603] With the employee posted before the G/L balancing account, the G/L side reuses the employee withholding.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" disabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", false);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] 500 posted in the period, below the threshold.
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, GLAccountNo, true, 500);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [WHEN] Post 600 with the employee as the account and the G/L account as the balancing account.
        CreateEmployeeJournalLine(GenJournalLine[2], WHTPostingSetup, EmployeeNo, GLAccountNo, true, 600);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        // [THEN] No tax for the first transaction; the second withholds 120 on 600 on both the employee and the G/L side.
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine[1]."Document No.", EmployeeNo, GLAccountNo, 500, 0, 500);
        VerifyPostedAmounts(WHTPostingSetup, GenJournalLine[2]."Document No.", EmployeeNo, GLAccountNo, 600, 120, 600);
        VerifyAccumulatedBase(EmployeeNo, 1100);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewHandler')]
    procedure PreviewPostingTaxAboveThresholdGLAccountFirst()
    begin
        // [SCENARIO 657603] Preview Posting of a G/L line with an employee balancing account shows the withheld amounts and posts nothing.
        PreviewPostingTaxAboveThreshold(false);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewHandler')]
    procedure PreviewPostingTaxAboveThresholdEmployeeAccountFirst()
    begin
        // [SCENARIO 657603] Preview Posting of an employee line with a G/L balancing account shows the withheld amounts and posts nothing.
        PreviewPostingTaxAboveThreshold(true);
    end;

    local procedure PreviewPostingTaxAboveThreshold(EmployeeIsAccount: Boolean)
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] Journal line for 3,000 between the employee and the G/L account.
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, GLAccountNo, EmployeeIsAccount, 3000);
        Commit();

        // [WHEN] Preview Posting.
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(WHTPostingSetup."Payable Wthldg. Tax Acc. Code");
        LibraryVariableStorage.Enqueue(3000);
        LibraryVariableStorage.Enqueue(400);
        LibraryVariableStorage.Enqueue(2000);
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [THEN] The preview shows the G/L account credited with 2,600, the withholding tax account with 400, the employee entry of 3,000 and a withholding entry of 400 on 2,000.
        Assert.ExpectedError('');
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Nothing is posted.
        WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
        Assert.RecordIsEmpty(WithholdingTaxEntry);
        VerifyAccumulatedBase(EmployeeNo, 0);
    end;

    [Test]
    procedure NetCalculationTaxAboveRecordThreshold()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        WHTEmployeeCalculation: Codeunit "WHT Employee Calculation";
        EmployeeNo: Code[20];
        WHTAmount: Decimal;
        WHTBaseAmount: Decimal;
    begin
        // [SCENARIO 657603] Net calculation grosses up the payment considering the threshold exemption.
        Initialize();

        // [GIVEN] Net calculation, Record/Line threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Net, "Withholding Threshold Base"::Record, true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);

        // [GIVEN] Employee journal line with a net amount of 3,000.
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, -3000);

        // [WHEN] Calculate employee withholding tax.
        WHTEmployeeCalculation.CalcEmployeeWHT(GenJournalLine, WHTAmount, WHTBaseAmount);

        // [THEN] Gross amount is 3,500, taxable base is 2,500 and withholding tax is 500, leaving the net 3,000.
        Assert.AreEqual(-3500, GenJournalLine.Amount, StrSubstNo(WrongValueErr, GenJournalLine.FieldCaption(Amount)));
        Assert.AreEqual(2500, WHTBaseAmount, StrSubstNo(WrongValueErr, 'withholding tax base'));
        Assert.AreEqual(500, WHTAmount, StrSubstNo(WrongValueErr, 'withholding tax amount'));
    end;

    [Test]
    procedure PendingExpenseLineBasesShareThreshold()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        WHTEmployeeCalculation: array[2] of Codeunit "WHT Employee Calculation";
        EmployeeNo: Code[20];
        WHTAmount: array[2] of Decimal;
        WHTBaseAmount: array[2] of Decimal;
    begin
        // [SCENARIO 657603] Lines calculated before the employee entry is posted, such as expense report lines, share one period threshold.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);

        // [GIVEN] Two lines of 1,500 each.
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, -1500);
        CreateEmployeeJournalLine(GenJournalLine[2], WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, -1500);

        // [WHEN] Calculate each line on a new calculation instance, registering the bases of the lines calculated before it.
        WHTEmployeeCalculation[1].CalcEmployeeWHT(GenJournalLine[1], WHTAmount[1], WHTBaseAmount[1]);
        WHTEmployeeCalculation[2].AddPendingThresholdBase(GenJournalLine[1], GenJournalLine[1].Amount);
        WHTEmployeeCalculation[2].CalcEmployeeWHT(GenJournalLine[2], WHTAmount[2], WHTBaseAmount[2]);

        // [THEN] The first line withholds 100 on 500, the second 300 on 1,500, 400 in total.
        Assert.AreEqual(500, WHTBaseAmount[1], StrSubstNo(WrongValueErr, 'first withholding tax base'));
        Assert.AreEqual(100, WHTAmount[1], StrSubstNo(WrongValueErr, 'first withholding tax amount'));
        Assert.AreEqual(1500, WHTBaseAmount[2], StrSubstNo(WrongValueErr, 'second withholding tax base'));
        Assert.AreEqual(300, WHTAmount[2], StrSubstNo(WrongValueErr, 'second withholding tax amount'));
    end;

    [Test]
    procedure DocumentThresholdLinesShareDocumentTotal()
    var
        WHTAmount: array[2] of Decimal;
        WHTBaseAmount: array[2] of Decimal;
    begin
        // [SCENARIO 657603] Expense lines of one document calculated one by one deduct the Document threshold once.
        // [GIVEN] Document threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        // [WHEN] Calculate two 1,500 lines of the same document, registering the first line before the second is calculated.
        CalcDocumentLines("Withholding Calculation Base"::Gross, true, -1500, -1500, WHTAmount, WHTBaseAmount);

        // [THEN] The first line withholds 100 on 500, the second 300 on 1,500, 400 in total.
        VerifyLineWHT(WHTAmount, WHTBaseAmount, 100, 500, 300, 1500);
    end;

    [Test]
    procedure DocumentThresholdOptionDisabledTaxesWholeDocument()
    var
        WHTAmount: array[2] of Decimal;
        WHTBaseAmount: array[2] of Decimal;
    begin
        // [SCENARIO 657603] When the document total reaches the Document threshold, the whole document is taxed.
        // [GIVEN] Document threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" disabled.
        // [WHEN] Calculate two 600 lines of the same document, registering the first line before the second is calculated.
        CalcDocumentLines("Withholding Calculation Base"::Gross, false, -600, -600, WHTAmount, WHTBaseAmount);

        // [THEN] The first line is below the threshold; the second withholds 240 on the document total 1,200.
        VerifyLineWHT(WHTAmount, WHTBaseAmount, 0, 600, 240, 1200);
    end;

    [Test]
    procedure NetDocumentThresholdLinesShareDocumentTotal()
    var
        WHTAmount: array[2] of Decimal;
        WHTBaseAmount: array[2] of Decimal;
    begin
        // [SCENARIO 657603] Net lines of one document gross up using the threshold remaining after earlier lines.
        // [GIVEN] Net calculation, Document threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        // [WHEN] Calculate two lines with net 1,500 each of the same document, registering the first gross line before the second is calculated.
        CalcDocumentLines("Withholding Calculation Base"::Net, true, -1500, -1500, WHTAmount, WHTBaseAmount);

        // [THEN] The first line grosses up to 1,625 and withholds 125 on 625; the second grosses up to 1,875 and withholds 375 on 1,875.
        VerifyLineWHT(WHTAmount, WHTBaseAmount, 125, 625, 375, 1875);
    end;

    [Test]
    procedure DocumentThresholdJournalLinesEmployeeAccountFirst()
    begin
        // [SCENARIO 657603] Posting a journal with two employee lines of one document deducts the Document threshold once.
        PostDocumentThresholdJournalLines(true, false);
    end;

    [Test]
    procedure DocumentThresholdJournalLinesGLAccountFirst()
    begin
        // [SCENARIO 657603] Posting a journal with two G/L lines with employee balancing accounts of one document deducts the Document threshold once.
        PostDocumentThresholdJournalLines(false, false);
    end;

    [Test]
    procedure DocumentThresholdPostingNoSeriesEmployeeAccountFirst()
    begin
        // [SCENARIO 657603] With a Posting No. Series on the batch, two employee lines of one document deduct the Document threshold once.
        PostDocumentThresholdJournalLines(true, true);
    end;

    [Test]
    procedure DocumentThresholdPostingNoSeriesGLAccountFirst()
    begin
        // [SCENARIO 657603] With a Posting No. Series on the batch, two G/L lines with employee balancing accounts of one document deduct the Document threshold once.
        PostDocumentThresholdJournalLines(false, true);
    end;

    local procedure PostDocumentThresholdJournalLines(EmployeeIsAccount: Boolean; UsePostingNoSeries: Boolean)
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Document threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::Document, true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] One journal batch with two lines of 1,500 each with the same document number, optionally renumbered by a Posting No. Series.
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, GLAccountNo, EmployeeIsAccount, 1500);
        CreateNextEmployeeJournalLine(GenJournalLine[2], GenJournalLine[1], GenJournalLine[1].Amount);
        if UsePostingNoSeries then
            SetPostingNoSeries(GenJournalLine);

        // [WHEN] Post the journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [THEN] Both lines are posted with one document number.
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        Assert.RecordCount(EmployeeLedgerEntry, 2);
        EmployeeLedgerEntry.FindFirst();
        PostedDocumentNo := EmployeeLedgerEntry."Document No.";
        if UsePostingNoSeries then
            Assert.AreNotEqual(GenJournalLine[1]."Document No.", PostedDocumentNo, StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption("Document No.")))
        else
            Assert.AreEqual(GenJournalLine[1]."Document No.", PostedDocumentNo, StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption("Document No.")));

        // [THEN] The first line withholds 100 on 500, the second 300 on 1,500, 400 in total.
        WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
        WithholdingTaxEntry.SetRange("Document No.", PostedDocumentNo);
        Assert.RecordCount(WithholdingTaxEntry, 2);
        WithholdingTaxEntry.SetRange(Amount, -100);
        WithholdingTaxEntry.SetRange(Base, 500);
        Assert.RecordCount(WithholdingTaxEntry, 1);
        WithholdingTaxEntry.SetRange(Amount, -300);
        WithholdingTaxEntry.SetRange(Base, 1500);
        Assert.RecordCount(WithholdingTaxEntry, 1);

        // [THEN] The employee entries total 3,000 with 400 withheld.
#pragma warning disable AA0210
        EmployeeLedgerEntry.SetRange("Document No.", PostedDocumentNo);
#pragma warning restore AA0210
        EmployeeLedgerEntry.CalcSums("Withholding Tax Amount");
        Assert.AreEqual(-400, EmployeeLedgerEntry."Withholding Tax Amount", StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption("Withholding Tax Amount")));

        // [THEN] On both account sides the G/L account is credited with 2,600 and the withholding tax account with 400.
        VerifyGLAmount(GLAccountNo, PostedDocumentNo, -2600);
        VerifyGLAmount(WHTPostingSetup."Payable Wthldg. Tax Acc. Code", PostedDocumentNo, -400);
    end;

    local procedure SetPostingNoSeries(var GenJournalLine: array[2] of Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PostingNoSeriesCode: Code[20];
        i: Integer;
    begin
        PostingNoSeriesCode := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Get(GenJournalLine[1]."Journal Template Name", GenJournalLine[1]."Journal Batch Name");
        GenJournalBatch."Posting No. Series" := PostingNoSeriesCode;
        GenJournalBatch.Modify();
        for i := 1 to 2 do begin
            GenJournalLine[i]."Posting No. Series" := PostingNoSeriesCode;
            GenJournalLine[i].Modify();
        end;
    end;

    [Test]
    procedure BufferedLinesAccumulateOriginalBases()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        WHTEmployeeCalculation: Codeunit "WHT Employee Calculation";
        EmployeeNo: Code[20];
        NextEntryNo: Integer;
    begin
        // [SCENARIO 657603] Withholding entries posted for several lines of one employee entry accumulate each line's original base.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);

        // [GIVEN] Employee line for the report net total 2,600 (3,000 less 400 withholding).
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, -2600);

        // [WHEN] Insert the withholding entries of two 1,500 lines, passing each line's original base.
        WHTEmployeeCalculation.InsertEmployeeWithholdingTaxEntry(GenJournalLine, 100, 500, 1500, 0, NextEntryNo);
        WHTEmployeeCalculation.InsertEmployeeWithholdingTaxEntry(GenJournalLine, 300, 1500, 1500, 0, NextEntryNo);

        // [THEN] Each entry stores 1,500 and the period accumulates 3,000 instead of twice the report net total.
        WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
        WithholdingTaxEntry.SetRange("Threshold Accum. Base Amount", 1500);
        Assert.RecordCount(WithholdingTaxEntry, 2);
        VerifyAccumulatedBase(EmployeeNo, 3000);
    end;

    [Test]
    procedure GroupedWithholdingUsesPostingSetupThreshold()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        ComponentWHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        WHTEmployeeCalculation: Codeunit "WHT Employee Calculation";
        WHTEmplGroupTestSubscr: Codeunit "WHT Empl. Group Test Subscr.";
        EmployeeNo: Code[20];
        WHTAmount: array[2] of Decimal;
        WHTBaseAmount: array[2] of Decimal;
    begin
        // [SCENARIO 657603] Grouped withholding applies the threshold of the line's posting setup.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000 with "Tax Only Amount Above Threshold" enabled on the line's posting setup.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);

        // [GIVEN] Withholding tax group with one 20 % component without a threshold.
        CreateComponentWHTPostingSetup(ComponentWHTPostingSetup, WHTPostingSetup."Wthldg. Tax Bus. Post. Group");
        WHTEmplGroupTestSubscr.SetWHTGroupCode(CreateWHTGroup(ComponentWHTPostingSetup."Wthldg. Tax Prod. Post. Group"));
        BindSubscription(WHTEmplGroupTestSubscr);

        // [GIVEN] Grouped lines of 500 and 3,000.
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, -500);
        CreateEmployeeJournalLine(GenJournalLine[2], WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, -3000);

        // [WHEN] Calculate employee withholding tax for each line.
        WHTEmployeeCalculation.CalcEmployeeWHT(GenJournalLine[1], WHTAmount[1], WHTBaseAmount[1]);
        WHTEmployeeCalculation.CalcEmployeeWHT(GenJournalLine[2], WHTAmount[2], WHTBaseAmount[2]);

        // [THEN] 500 is below the threshold; 3,000 withholds 400 on the taxable base 2,000.
        Assert.AreEqual(0, WHTAmount[1], StrSubstNo(WrongValueErr, 'withholding tax amount below threshold'));
        Assert.AreEqual(2000, WHTBaseAmount[2], StrSubstNo(WrongValueErr, 'withholding tax base'));
        Assert.AreEqual(400, WHTAmount[2], StrSubstNo(WrongValueErr, 'withholding tax amount'));

        UnbindSubscription(WHTEmplGroupTestSubscr);
    end;

    [Test]
    procedure GroupedBelowThresholdPostsNoWithholding()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        ComponentWHTPostingSetup: array[2] of Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        WHTEmplGroupTestSubscr: Codeunit "WHT Empl. Group Test Subscr.";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 657603] Posting a grouped transaction below the threshold posts no component withholding.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000 with "Tax Only Amount Above Threshold" enabled and a group with one 20 % component.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        CreateComponentWHTPostingSetup(ComponentWHTPostingSetup[1], WHTPostingSetup."Wthldg. Tax Bus. Post. Group");
        WHTEmplGroupTestSubscr.SetWHTGroupCode(CreateWHTGroup(ComponentWHTPostingSetup[1]."Wthldg. Tax Prod. Post. Group"));
        BindSubscription(WHTEmplGroupTestSubscr);

        // [WHEN] Post 500 with the employee as the account.
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, GLAccountNo, true, 500);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] No withholding is posted for the component and the period accumulates 500.
        VerifyGroupedPostedAmounts(ComponentWHTPostingSetup, 1, GenJournalLine."Document No.", EmployeeNo, GLAccountNo, 500, 0, 500);
        VerifyAccumulatedBase(EmployeeNo, 500);

        UnbindSubscription(WHTEmplGroupTestSubscr);
    end;

    [Test]
    procedure GroupedTaxAboveThresholdEmployeeAccountFirst()
    begin
        // [SCENARIO 657603] A grouped employee line with a G/L balancing account calculates the same withholding on both sides.
        PostGroupedTaxAboveThreshold(true);
    end;

    [Test]
    procedure GroupedTaxAboveThresholdGLAccountFirst()
    begin
        // [SCENARIO 657603] A grouped G/L line with an employee balancing account calculates the same withholding on both sides.
        PostGroupedTaxAboveThreshold(false);
    end;

    local procedure PostGroupedTaxAboveThreshold(EmployeeIsAccount: Boolean)
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        ComponentWHTPostingSetup: array[2] of Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        WHTEmplGroupTestSubscr: Codeunit "WHT Empl. Group Test Subscr.";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
        WHTGroupCode: Code[20];
    begin
        Initialize();

        // [GIVEN] Total in Period threshold 1,000 with "Tax Only Amount Above Threshold" enabled and a group with two Simple 20 % components.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        CreateComponentWHTPostingSetup(ComponentWHTPostingSetup[1], WHTPostingSetup."Wthldg. Tax Bus. Post. Group");
        CreateComponentWHTPostingSetup(ComponentWHTPostingSetup[2], WHTPostingSetup."Wthldg. Tax Bus. Post. Group");
        WHTGroupCode := CreateWHTGroup(ComponentWHTPostingSetup[1]."Wthldg. Tax Prod. Post. Group");
        AddWHTGroupLine(WHTGroupCode, ComponentWHTPostingSetup[2]."Wthldg. Tax Prod. Post. Group", 2);
        WHTEmplGroupTestSubscr.SetWHTGroupCode(WHTGroupCode);
        BindSubscription(WHTEmplGroupTestSubscr);

        // [WHEN] Post 3,000 between the employee and the G/L account.
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, GLAccountNo, EmployeeIsAccount, 3000);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Each component withholds 400 on the taxable base 2,000, 800 in total; the G/L account is credited with 2,200.
        VerifyGroupedPostedAmounts(ComponentWHTPostingSetup, 2, GenJournalLine."Document No.", EmployeeNo, GLAccountNo, 3000, 400, 2000);

        // [THEN] The period accumulates the original base 3,000 once.
        VerifyAccumulatedBase(EmployeeNo, 3000);

        UnbindSubscription(WHTEmplGroupTestSubscr);
    end;

    [Test]
    procedure ReverseGroupedEntriesRemovesOriginalBaseOnce()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        ComponentWHTPostingSetup: array[2] of Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        WHTEmployeeCalculation: Codeunit "WHT Employee Calculation";
        WHTEmplGroupTestSubscr: Codeunit "WHT Empl. Group Test Subscr.";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
        WHTGroupCode: Code[20];
    begin
        // [SCENARIO 657603] Reversing the entries of a grouped transaction removes its original base from the period exactly once.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000 with "Tax Only Amount Above Threshold" enabled and a group with two Simple 20 % components.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        CreateComponentWHTPostingSetup(ComponentWHTPostingSetup[1], WHTPostingSetup."Wthldg. Tax Bus. Post. Group");
        CreateComponentWHTPostingSetup(ComponentWHTPostingSetup[2], WHTPostingSetup."Wthldg. Tax Bus. Post. Group");
        WHTGroupCode := CreateWHTGroup(ComponentWHTPostingSetup[1]."Wthldg. Tax Prod. Post. Group");
        AddWHTGroupLine(WHTGroupCode, ComponentWHTPostingSetup[2]."Wthldg. Tax Prod. Post. Group", 2);
        WHTEmplGroupTestSubscr.SetWHTGroupCode(WHTGroupCode);
        BindSubscription(WHTEmplGroupTestSubscr);

        // [GIVEN] Grouped transaction of 3,000 posted with two component withholding entries.
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, GLAccountNo, true, 3000);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);
        VerifyAccumulatedBase(EmployeeNo, 3000);

        // [WHEN] Reverse the threshold accumulation of each withholding entry of the transaction.
#pragma warning disable AA0210
        WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
#pragma warning restore AA0210
        WithholdingTaxEntry.SetRange("Document No.", GenJournalLine[1]."Document No.");
        Assert.RecordCount(WithholdingTaxEntry, 2);
        WithholdingTaxEntry.FindSet();
        repeat
            WHTEmployeeCalculation.ReverseThresholdAccumulator(WithholdingTaxEntry);
        until WithholdingTaxEntry.Next() = 0;

        // [THEN] The original base 3,000 is removed once and the period is back to zero.
        VerifyAccumulatedBase(EmployeeNo, 0);

        // [WHEN] Post a grouped transaction of 500 in the same period.
        CreateEmployeeJournalLine(GenJournalLine[2], WHTPostingSetup, EmployeeNo, GLAccountNo, true, 500);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        // [THEN] 500 is below the threshold and nothing is withheld.
        VerifyGroupedPostedAmounts(ComponentWHTPostingSetup, 2, GenJournalLine[2]."Document No.", EmployeeNo, GLAccountNo, 500, 0, 500);
        VerifyAccumulatedBase(EmployeeNo, 500);

        UnbindSubscription(WHTEmplGroupTestSubscr);
    end;

    [Test]
    procedure ReverseLegacyEntryRemovesTaxableBase()
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        LastWithholdingTaxEntry: Record "Withholding Tax Entry";
        WHTEmployeeCalculation: Codeunit "WHT Employee Calculation";
        EmployeeNo: Code[20];
    begin
        // [SCENARIO 657603] Reversing an entry posted before "Threshold Accum. Base Amount" existed removes its taxable base from the period.
        Initialize();

        // [GIVEN] Total in Period threshold setup and an employee.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", false);
        EmployeeNo := CreateEmployee(WHTPostingSetup);

        // [GIVEN] Legacy withholding entry with taxable base 2,000 and no "Threshold Accum. Base Amount".
        if LastWithholdingTaxEntry.FindLast() then;
        WithholdingTaxEntry."Entry No." := LastWithholdingTaxEntry."Entry No." + 1;
        WithholdingTaxEntry."Party Type" := "Withholding Party Type"::Employee;
        WithholdingTaxEntry."Employee No." := EmployeeNo;
        WithholdingTaxEntry."Wthldg. Tax Bus. Post. Group" := WHTPostingSetup."Wthldg. Tax Bus. Post. Group";
        WithholdingTaxEntry."Wthldg. Tax Prod. Post. Group" := WHTPostingSetup."Wthldg. Tax Prod. Post. Group";
        WithholdingTaxEntry."Posting Date" := WorkDate();
        WithholdingTaxEntry."Taxable Base Amount" := 2000;
        WithholdingTaxEntry.Amount := -400;
        WithholdingTaxEntry.Insert();

        // [WHEN] Reverse the threshold accumulation of the entry.
        WHTEmployeeCalculation.ReverseThresholdAccumulator(WithholdingTaxEntry);

        // [THEN] The period accumulator is reduced by the taxable base 2,000.
        VerifyAccumulatedBase(EmployeeNo, -2000);
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Enable Withholding Tax" := true;
        GeneralLedgerSetup.Modify();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateEmployeeWHTPostingSetup(var WHTPostingSetup: Record "Withholding Tax Posting Setup"; CalculationBase: Enum "Withholding Calculation Base"; ThresholdBase: Enum "Withholding Threshold Base"; TaxAmountAboveThreshold: Boolean)
    var
        WHTBusinessPostingGroup: Record "Wthldg. Tax Bus. Post. Group";
        WHTProductPostingGroup: Record "Wthldg. Tax Prod. Post. Group";
    begin
        LibraryWithholdingTax.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        WHTBusinessPostingGroup.Validate("Party Applicability", "Withholding Party Type"::Employee);
        WHTBusinessPostingGroup.Modify(true);
        LibraryWithholdingTax.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        LibraryWithholdingTax.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);

        WHTPostingSetup.Validate("Withholding Tax %", 20);
        WHTPostingSetup.Validate("Wthldg. Tax Min. Inv. Amount", 1000);
        WHTPostingSetup.Validate("Calculation Base", CalculationBase);
        WHTPostingSetup.Validate("WHT Threshold Base", ThresholdBase);
        if ThresholdBase in ["Withholding Threshold Base"::"Category Period", "Withholding Threshold Base"::"Total Period"] then
            WHTPostingSetup.Validate("WHT Threshold Period", "WHT Threshold Period Type"::Month);
        WHTPostingSetup.Validate("Tax Amount Above Threshold", TaxAmountAboveThreshold);
        WHTPostingSetup.Validate("Payable Wthldg. Tax Acc. Code", LibraryERM.CreateGLAccountNoWithDirectPosting());
        WHTPostingSetup.Modify(true);
    end;

    local procedure CalcDocumentLines(CalculationBase: Enum "Withholding Calculation Base"; TaxAmountAboveThreshold: Boolean; FirstAmount: Decimal; SecondAmount: Decimal; var WHTAmount: array[2] of Decimal; var WHTBaseAmount: array[2] of Decimal)
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        WHTEmployeeCalculation: array[2] of Codeunit "WHT Employee Calculation";
        EmployeeNo: Code[20];
    begin
        Initialize();

        CreateEmployeeWHTPostingSetup(WHTPostingSetup, CalculationBase, "Withholding Threshold Base"::Document, TaxAmountAboveThreshold);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        CreateEmployeeJournalLine(GenJournalLine[1], WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, FirstAmount);
        CreateEmployeeJournalLine(GenJournalLine[2], WHTPostingSetup, EmployeeNo, LibraryERM.CreateGLAccountNoWithDirectPosting(), true, SecondAmount);
        GenJournalLine[2]."Document No." := GenJournalLine[1]."Document No.";

        // Each line is calculated on a new instance, seeded with the lines calculated before it, as the expense report posting does.
        WHTEmployeeCalculation[1].CalcEmployeeWHT(GenJournalLine[1], WHTAmount[1], WHTBaseAmount[1]);
        WHTEmployeeCalculation[2].AddPendingThresholdBase(GenJournalLine[1], GenJournalLine[1].Amount);
        WHTEmployeeCalculation[2].CalcEmployeeWHT(GenJournalLine[2], WHTAmount[2], WHTBaseAmount[2]);
    end;

    local procedure VerifyLineWHT(WHTAmount: array[2] of Decimal; WHTBaseAmount: array[2] of Decimal; ExpectedFirstWHTAmount: Decimal; ExpectedFirstWHTBase: Decimal; ExpectedSecondWHTAmount: Decimal; ExpectedSecondWHTBase: Decimal)
    begin
        Assert.AreEqual(ExpectedFirstWHTBase, WHTBaseAmount[1], StrSubstNo(WrongValueErr, 'first withholding tax base'));
        Assert.AreEqual(ExpectedFirstWHTAmount, WHTAmount[1], StrSubstNo(WrongValueErr, 'first withholding tax amount'));
        Assert.AreEqual(ExpectedSecondWHTBase, WHTBaseAmount[2], StrSubstNo(WrongValueErr, 'second withholding tax base'));
        Assert.AreEqual(ExpectedSecondWHTAmount, WHTAmount[2], StrSubstNo(WrongValueErr, 'second withholding tax amount'));
    end;

    local procedure CreateComponentWHTPostingSetup(var WHTPostingSetup: Record "Withholding Tax Posting Setup"; WHTBusPostingGroupCode: Code[20])
    var
        WHTProductPostingGroup: Record "Wthldg. Tax Prod. Post. Group";
    begin
        LibraryWithholdingTax.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        LibraryWithholdingTax.CreateWHTPostingSetup(WHTPostingSetup, WHTBusPostingGroupCode, WHTProductPostingGroup.Code);
        WHTPostingSetup.Validate("Withholding Tax %", 20);
        WHTPostingSetup.Validate("Payable Wthldg. Tax Acc. Code", LibraryERM.CreateGLAccountNoWithDirectPosting());
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateWHTGroup(ComponentProdPostingGroupCode: Code[20]): Code[20]
    var
        WithholdingTaxGroup: Record "Withholding Tax Group";
    begin
        WithholdingTaxGroup.Validate(Code, LibraryUtility.GenerateRandomCode(WithholdingTaxGroup.FieldNo(Code), Database::"Withholding Tax Group"));
        WithholdingTaxGroup.Insert(true);
        AddWHTGroupLine(WithholdingTaxGroup.Code, ComponentProdPostingGroupCode, 1);
        exit(WithholdingTaxGroup.Code);
    end;

    local procedure AddWHTGroupLine(WHTGroupCode: Code[20]; ComponentProdPostingGroupCode: Code[20]; ComponentOrder: Integer)
    var
        WithholdingTaxGroupLine: Record "Withholding Tax Group Line";
    begin
        WithholdingTaxGroupLine.Validate("Group Code", WHTGroupCode);
        WithholdingTaxGroupLine.Validate("Line No.", ComponentOrder * 10000);
        WithholdingTaxGroupLine.Validate("Wthldg. Tax Prod. Post. Group", ComponentProdPostingGroupCode);
        WithholdingTaxGroupLine.Validate("Component Order", ComponentOrder);
        WithholdingTaxGroupLine.Insert(true);
    end;

    local procedure VerifyGroupedPostedAmounts(ComponentWHTPostingSetup: array[2] of Record "Withholding Tax Posting Setup"; ComponentCount: Integer; DocumentNo: Code[20]; EmployeeNo: Code[20]; GLAccountNo: Code[20]; EmployeeAmount: Decimal; ExpectedComponentWHTAmount: Decimal; ExpectedWHTBase: Decimal)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        i: Integer;
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
#pragma warning disable AA0210
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
#pragma warning restore AA0210
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields(Amount);
        Assert.AreEqual(EmployeeAmount, EmployeeLedgerEntry.Amount, StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption(Amount)));
        Assert.AreEqual(-ExpectedComponentWHTAmount * ComponentCount, EmployeeLedgerEntry."Withholding Tax Amount", StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption("Withholding Tax Amount")));
        Assert.AreEqual(ExpectedWHTBase, EmployeeLedgerEntry."Withholding Tax Base Amount", StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption("Withholding Tax Base Amount")));

        VerifyGLAmount(GLAccountNo, DocumentNo, -(EmployeeAmount - ExpectedComponentWHTAmount * ComponentCount));
        for i := 1 to ComponentCount do begin
            VerifyGLAmount(ComponentWHTPostingSetup[i]."Payable Wthldg. Tax Acc. Code", DocumentNo, -ExpectedComponentWHTAmount);

            WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
            WithholdingTaxEntry.SetRange("Document No.", DocumentNo);
            WithholdingTaxEntry.SetRange("Wthldg. Tax Prod. Post. Group", ComponentWHTPostingSetup[i]."Wthldg. Tax Prod. Post. Group");
            if ExpectedComponentWHTAmount = 0 then
                Assert.RecordIsEmpty(WithholdingTaxEntry)
            else begin
                WithholdingTaxEntry.FindFirst();
                Assert.AreEqual(-ExpectedComponentWHTAmount, WithholdingTaxEntry.Amount, StrSubstNo(WrongValueErr, WithholdingTaxEntry.FieldCaption(Amount)));
                Assert.AreEqual(ExpectedWHTBase, WithholdingTaxEntry.Base, StrSubstNo(WrongValueErr, WithholdingTaxEntry.FieldCaption(Base)));
            end;
        end;
    end;

    local procedure CreateEmployee(WHTPostingSetup: Record "Withholding Tax Posting Setup"): Code[20]
    var
        Employee: Record Employee;
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Wthldg. Tax Bus. Post. Group" := WHTPostingSetup."Wthldg. Tax Bus. Post. Group";
        Employee.Modify(true);
        exit(Employee."No.");
    end;

    local procedure CreateEmployeeJournalLine(var GenJournalLine: Record "Gen. Journal Line"; WHTPostingSetup: Record "Withholding Tax Posting Setup"; EmployeeNo: Code[20]; GLAccountNo: Code[20]; EmployeeIsAccount: Boolean; EmployeeAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        if EmployeeIsAccount then
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::Employee, EmployeeNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo, EmployeeAmount)
        else
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Bal. Account Type"::Employee, EmployeeNo, -EmployeeAmount);

        GenJournalLine."Wthldg. Tax Bus. Post. Group" := WHTPostingSetup."Wthldg. Tax Bus. Post. Group";
        GenJournalLine."Wthldg. Tax Prod. Post. Group" := WHTPostingSetup."Wthldg. Tax Prod. Post. Group";
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyPostedAmounts(WHTPostingSetup: Record "Withholding Tax Posting Setup"; DocumentNo: Code[20]; EmployeeNo: Code[20]; GLAccountNo: Code[20]; EmployeeAmount: Decimal; ExpectedWHTAmount: Decimal; ExpectedWHTBase: Decimal)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
#pragma warning disable AA0210
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
#pragma warning restore AA0210
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields(Amount);
        Assert.AreEqual(EmployeeAmount, EmployeeLedgerEntry.Amount, StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption(Amount)));
        Assert.AreEqual(-ExpectedWHTAmount, EmployeeLedgerEntry."Withholding Tax Amount", StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption("Withholding Tax Amount")));
        Assert.AreEqual(ExpectedWHTBase, EmployeeLedgerEntry."Withholding Tax Base Amount", StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption("Withholding Tax Base Amount")));

        WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
        WithholdingTaxEntry.SetRange("Document No.", DocumentNo);
        if ExpectedWHTAmount = 0 then
            Assert.RecordIsEmpty(WithholdingTaxEntry)
        else begin
            WithholdingTaxEntry.FindFirst();
            Assert.AreEqual(-ExpectedWHTAmount, WithholdingTaxEntry.Amount, StrSubstNo(WrongValueErr, WithholdingTaxEntry.FieldCaption(Amount)));
            Assert.AreEqual(ExpectedWHTBase, WithholdingTaxEntry.Base, StrSubstNo(WrongValueErr, WithholdingTaxEntry.FieldCaption(Base)));
            Assert.AreEqual(EmployeeAmount, WithholdingTaxEntry."Threshold Accum. Base Amount", StrSubstNo(WrongValueErr, WithholdingTaxEntry.FieldCaption("Threshold Accum. Base Amount")));
        end;

        VerifyGLAmount(GLAccountNo, DocumentNo, -(EmployeeAmount - ExpectedWHTAmount));
        VerifyGLAmount(WHTPostingSetup."Payable Wthldg. Tax Acc. Code", DocumentNo, -ExpectedWHTAmount);
    end;

    local procedure CreateNextEmployeeJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PreviousGenJournalLine: Record "Gen. Journal Line"; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, PreviousGenJournalLine."Journal Template Name", PreviousGenJournalLine."Journal Batch Name", PreviousGenJournalLine."Document Type",
          PreviousGenJournalLine."Account Type", PreviousGenJournalLine."Account No.", PreviousGenJournalLine."Bal. Account Type", PreviousGenJournalLine."Bal. Account No.", LineAmount);
        GenJournalLine.Validate("Document No.", PreviousGenJournalLine."Document No.");
        GenJournalLine."Wthldg. Tax Bus. Post. Group" := PreviousGenJournalLine."Wthldg. Tax Bus. Post. Group";
        GenJournalLine."Wthldg. Tax Prod. Post. Group" := PreviousGenJournalLine."Wthldg. Tax Prod. Post. Group";
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyGLAmount(GLAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, StrSubstNo(WrongValueErr, GLEntry.FieldCaption(Amount)));
    end;

    local procedure VerifyAccumulatedBase(EmployeeNo: Code[20]; ExpectedAmount: Decimal)
    var
        WHTThresholdAccumulator: Record "WHT Threshold Accumulator";
    begin
        WHTThresholdAccumulator.SetRange("Employee No.", EmployeeNo);
        WHTThresholdAccumulator.CalcSums("Accumulated Base Amount");
        Assert.AreEqual(ExpectedAmount, WHTThresholdAccumulator."Accumulated Base Amount", StrSubstNo(WrongValueErr, WHTThresholdAccumulator.FieldCaption("Accumulated Base Amount")));
    end;

    [PageHandler]
    procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    var
        GLEntriesPreview: TestPage "G/L Entries Preview";
        EmplLedgerEntriesPreview: TestPage "Empl. Ledger Entries Preview";
        WithholdingTaxEntries: TestPage "Withholding Tax Entries";
        GLAccountNo: Code[20];
        PayableAccountNo: Code[20];
        EmployeeAmount: Decimal;
        WHTAmount: Decimal;
        WHTBaseAmount: Decimal;
    begin
        GLAccountNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(GLAccountNo));
        PayableAccountNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PayableAccountNo));
        EmployeeAmount := LibraryVariableStorage.DequeueDecimal();
        WHTAmount := LibraryVariableStorage.DequeueDecimal();
        WHTBaseAmount := LibraryVariableStorage.DequeueDecimal();

        GLEntriesPreview.Trap();
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"G/L Entry"));
        GLPostingPreview.Show.Invoke();
        GLEntriesPreview.Filter.SetFilter("G/L Account No.", GLAccountNo);
        Assert.IsTrue(GLEntriesPreview.First(), StrSubstNo(WrongValueErr, 'preview G/L account entry'));
        GLEntriesPreview.Amount.AssertEquals(-(EmployeeAmount - WHTAmount));
        GLEntriesPreview.Filter.SetFilter("G/L Account No.", PayableAccountNo);
        Assert.IsTrue(GLEntriesPreview.First(), StrSubstNo(WrongValueErr, 'preview withholding tax G/L entry'));
        GLEntriesPreview.Amount.AssertEquals(-WHTAmount);
        GLEntriesPreview.Close();

        EmplLedgerEntriesPreview.Trap();
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Employee Ledger Entry"));
        GLPostingPreview.Show.Invoke();
        Assert.IsTrue(EmplLedgerEntriesPreview.First(), StrSubstNo(WrongValueErr, 'preview employee ledger entry'));
        EmplLedgerEntriesPreview.AmountFCY.AssertEquals(EmployeeAmount);
        EmplLedgerEntriesPreview.Close();

        WithholdingTaxEntries.Trap();
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Withholding Tax Entry"));
        GLPostingPreview.Show.Invoke();
        Assert.IsTrue(WithholdingTaxEntries.First(), StrSubstNo(WrongValueErr, 'preview withholding tax entry'));
        WithholdingTaxEntries.Amount.AssertEquals(-WHTAmount);
        WithholdingTaxEntries.Base.AssertEquals(WHTBaseAmount);
        WithholdingTaxEntries.Close();
    end;
}
