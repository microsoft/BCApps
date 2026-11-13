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
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 657603] Preview Posting of a G/L line with an employee balancing account produces a consistent transaction and posts nothing.
        Initialize();

        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        CreateEmployeeWHTPostingSetup(WHTPostingSetup, "Withholding Calculation Base"::Gross, "Withholding Threshold Base"::"Total Period", true);
        EmployeeNo := CreateEmployee(WHTPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] Journal line for 3,000 with the G/L account as the account and the employee as the balancing account.
        CreateEmployeeJournalLine(GenJournalLine, WHTPostingSetup, EmployeeNo, GLAccountNo, false, 3000);
        Commit();

        // [WHEN] Preview Posting.
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [THEN] The preview completes without an inconsistency error and shows the G/L account, employee payables and withholding tax G/L entries.
        Assert.ExpectedError('');

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
        WithholdingTaxEntry.SetRange("Threshold Accum. Base Amt.", 1500);
        Assert.RecordCount(WithholdingTaxEntry, 2);
        VerifyAccumulatedBase(EmployeeNo, 3000);
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibrarySetupStorage.Restore();

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
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
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
            Assert.AreEqual(EmployeeAmount, WithholdingTaxEntry."Threshold Accum. Base Amt.", StrSubstNo(WrongValueErr, WithholdingTaxEntry.FieldCaption("Threshold Accum. Base Amt.")));
        end;

        VerifyGLAmount(GLAccountNo, DocumentNo, -(EmployeeAmount - ExpectedWHTAmount));
        VerifyGLAmount(WHTPostingSetup."Payable Wthldg. Tax Acc. Code", DocumentNo, -ExpectedWHTAmount);
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
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"G/L Entry"));
        Assert.IsTrue(GLPostingPreview.First(), StrSubstNo(WrongValueErr, 'preview G/L entries'));
    end;
}
