// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports.Test;

using Microsoft.Finance.ExcelReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Period;
using System.TestLibraries.Utilities;

codeunit 139545 "Fixed Asset Excel Reports"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ProjectedDeprMismatchLbl: Label 'Projected depreciation should be calculated from the latest closing book value.';

    [Test]
    [HandlerFunctions('EXRFixedAssetAnalysisExcelHandler')]
    procedure FirstTimeOpeningRequestPageOfFixedAssetAnalysisShouldInsertPostingTypes()
    var
        RequestPageXml: Text;
    begin
        // [SCENARIO 544231] First time opening the Fixed Asset Analysis Excel report requestpage should insert the FixedAssetTypes required by the report
        // [GIVEN] There is no FA Posting Type
        CleanupFixedAssetData();
        Commit();
        Assert.TableIsEmpty(Database::"FA Posting Type");
        // [WHEN] Opening the requestpage of the Fixed Asset Analysis report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Fixed Asset Analysis Excel", RequestPageXml);
        // [THEN] The default FA Posting Type's are inserted
        Assert.TableIsNotEmpty(Database::"FA Posting Type");
    end;

    [Test]
    [HandlerFunctions('EXRFixedAssetAnalysisExcelHandler')]
    procedure FixedAssetAnalysisShouldntExportFixedAssetWithoutEntries()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        Variant: Variant;
        VariantText: Text;
        ReportAcquisitionDate: Date;
        RequestPageXml: Text;
    begin
        // [SCENARIO 546182] Fixed Asset Analysis report should report the correct acquisition date and not export fixed assets if they have no entries.
        CleanupFixedAssetData();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        // [GIVEN] An acquired fixed asset
        FixedAsset."No." := 'FA01';
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook."Acquisition Date" := WorkDate();
        FADepreciationBook.Modify();
        // [GIVEN] An unacquired fixed asset (no entries)
        FixedAsset."No." := 'FA02';
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        Commit();
        // [WHEN] Running the fixed asset analysis excel report
        LibraryVariableStorage.Enqueue(DepreciationBook.Code);
        RequestPageXml := Report.RunRequestPage(Report::"EXR Fixed Asset Analysis Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(report::"EXR Fixed Asset Analysis Excel", Variant, RequestPageXml);
        // [THEN] The dataset contains both fixed assets
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="FixedAssetData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Just the acquired fixed asset should be exported on the report');
        // [THEN] Only the first fixed asset has defined AcquisitionDate
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('AcquisitionDateField', Variant);
        VariantText := Variant;
        Evaluate(ReportAcquisitionDate, VariantText);
        Assert.AreEqual(FADepreciationBook."Acquisition Date", ReportAcquisitionDate, 'Acquisition date of first fixed asset should match the one in the depreciation book');
    end;

    local procedure CleanupFixedAssetData()
    var
        FAPostingType: Record "FA Posting Type";
        FixedAsset: Record "Fixed Asset";
    begin
        FAPostingType.DeleteAll();
        FixedAsset.DeleteAll();
    end;

    [RequestPageHandler]
    procedure EXRFixedAssetAnalysisExcelHandler(var EXRFixedAssetAnalysisExcel: TestRequestPage "EXR Fixed Asset Analysis Excel")
    var
        DepreciationBookCode: Code[10];
    begin
        if LibraryVariableStorage.Length() = 1 then begin
            DepreciationBookCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, 10);
            EXRFixedAssetAnalysisExcel.DepreciationBookCodeField.SetValue(DepreciationBookCode);
        end;
        EXRFixedAssetAnalysisExcel.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('EXRFixedAssetProjectedHandler')]
    procedure ProjectedValueDeclBalShouldUseCorrectBookValueAcrossFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
        Variant: Variant;
        RequestPageXml: Text;
        AcquisitionAmount: Decimal;
        DecliningBalancePct: Decimal;
        AcquisitionDate: Date;
        DeprStartDate: Date;
        FiscalYearStartDate: Date;
        FirstReportDeprDate: Date;
        LastReportDeprDate: Date;
        MonthlyDeprAmount: Decimal;
        BookValueAfterDepr: Decimal;
        ExpectedProjectedDepr: Decimal;
        BasePostingDate: Date;
        PostingDate: Date;
        I: Integer;
        ReportAmount: Decimal;
    begin
        // [SCENARIO 631253] Report 4413 "Fixed Asset Projected Value (Excel)" should calculate depreciation
        // using the last posted month's book value when crossing a fiscal year boundary with Declining-Balance 1.
        // Previously it incorrectly used the penultimate month's book value.

        // [GIVEN] Create Accounting periods with fiscal year.
        CleanupFixedAssetData();
        AccountingPeriod.DeleteAll();
        FiscalYearStartDate := DMY2Date(1, 9, 2025);
        CreateMonthlyAccountingPeriods(FiscalYearStartDate, 24);

        // [GIVEN] Create a depreciation book.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        SetupFAJournalSetup(FAJournalSetup);

        // [GIVEN] Create a fixed asset with Declining-Balance 1 and randomized amount/% values.
        AcquisitionDate := DMY2Date(1, 1, 2025);
        DeprStartDate := AcquisitionDate;
        AcquisitionAmount := 10000 + Round(LibraryRandom.RandDec(90000, 0), 1);
        DecliningBalancePct := 10 + Round(LibraryRandom.RandDec(20, 0), 1);

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        EnsureGeneralPostingSetupForFA(FixedAsset."FA Posting Group");
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", DeprStartDate);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        FADepreciationBook.Validate("Declining-Balance %", DecliningBalancePct);
        FADepreciationBook.Modify(true);

        if FASetup.Get() then begin
            FASetup.Validate("Default Depr. Book", DepreciationBook.Code);
            FASetup.Modify();
        end;

        // [GIVEN] Post acquisition on the randomized acquisition date.
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalTemplate.Name, FAJournalBatch.Name);
        FAJournalLine.Validate("FA No.", FixedAsset."No.");
        FAJournalLine.Validate("FA Posting Date", AcquisitionDate);
        FAJournalLine.Validate("Posting Date", AcquisitionDate);
        FAJournalLine.Validate("FA Posting Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        FAJournalLine.Validate(Amount, AcquisitionAmount);
        FAJournalLine.Validate("Document No.", FixedAsset."No.");
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [GIVEN] Post depreciation starting from the acquisition month.
        BasePostingDate := CalcDate('<CM>', AcquisitionDate);
        BookValueAfterDepr := AcquisitionAmount;
        for I := 1 to 8 do begin
            MonthlyDeprAmount := Round(BookValueAfterDepr * DecliningBalancePct / 100 / 12, 1);
            PostingDate := CalcDate('<' + Format(I - 1) + 'M>', BasePostingDate);

            LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
            LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalTemplate.Name, FAJournalBatch.Name);
            FAJournalLine.Validate("FA No.", FixedAsset."No.");
            FAJournalLine.Validate("FA Posting Date", PostingDate);
            FAJournalLine.Validate("Posting Date", PostingDate);
            FAJournalLine.Validate("FA Posting Type", FAJournalLine."FA Posting Type"::Depreciation);
            FAJournalLine.Validate("Depreciation Book Code", DepreciationBook.Code);
            FAJournalLine.Validate(Amount, -MonthlyDeprAmount);
            FAJournalLine.Validate("Document No.", FixedAsset."No." + '-' + Format(I));
            FAJournalLine.Modify(true);
            LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

            BookValueAfterDepr -= MonthlyDeprAmount;
        end;

        // The next projected month should be based on this closing book value.
        ExpectedProjectedDepr := -Round(BookValueAfterDepr * DecliningBalancePct / 100 / 12, 1);
        Commit();

        // [WHEN] Running the Fixed Asset Projected Value (Excel) report.
        FirstReportDeprDate := CalcDate('<CM>', CalcDate('<8M>', BasePostingDate));
        LastReportDeprDate := CalcDate('<11M>', FirstReportDeprDate);
        LibraryVariableStorage.Enqueue(DepreciationBook.Code);
        LibraryVariableStorage.Enqueue(FirstReportDeprDate);
        LibraryVariableStorage.Enqueue(LastReportDeprDate);
        LibraryVariableStorage.Enqueue(false); // Use Accounting Period
        RequestPageXml := Report.RunRequestPage(Report::"EXR Fixed Asset Projected", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Fixed Asset Projected", Variant, RequestPageXml);

        // [THEN] Verify the projected depreciation in the first projected month uses the latest closing book value.
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="FixedAssetLedgerEntries"]');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Amount', Variant);
        ReportAmount := Variant;
        ReportAmount := Round(ReportAmount, 1);
        Assert.AreEqual(ExpectedProjectedDepr, ReportAmount, ProjectedDeprMismatchLbl);
    end;

    local procedure CreateMonthlyAccountingPeriods(FiscalYearStart: Date; NumberOfMonths: Integer)
    var
        AccountingPeriod: Record "Accounting Period";
        PeriodStart: Date;
        I: Integer;
    begin
        // Create a fiscal year starting at FiscalYearStart with monthly periods
        // Also create the prior fiscal year.
        PeriodStart := CalcDate('<-1Y>', FiscalYearStart);
        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := PeriodStart;
        AccountingPeriod."New Fiscal Year" := true;
        AccountingPeriod.Insert();
        for I := 1 to 11 do begin
            PeriodStart := CalcDate('<1M>', PeriodStart);
            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := PeriodStart;
            AccountingPeriod."New Fiscal Year" := false;
            AccountingPeriod.Insert();
        end;

        // Create the target fiscal year and its periods.
        for I := 0 to NumberOfMonths - 1 do begin
            PeriodStart := CalcDate('<' + Format(I) + 'M>', FiscalYearStart);
            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := PeriodStart;
            AccountingPeriod."New Fiscal Year" := (I = 0);
            AccountingPeriod.Insert();
        end;
    end;

    local procedure SetupFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        DefaultFAJournalSetup: Record "FA Journal Setup";
    begin
        DefaultFAJournalSetup.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        if DefaultFAJournalSetup.FindFirst() then begin
            FAJournalSetup.TransferFields(DefaultFAJournalSetup, false);
            FAJournalSetup.Modify(true);
        end;
    end;

    local procedure EnsureGeneralPostingSetupForFA(FAPostingGroupCode: Code[20])
    var
        FAPostingGrp: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not FAPostingGrp.Get(FAPostingGroupCode) then
            exit;
        if not GLAccount.Get(FAPostingGrp."Acquisition Cost Account") then
            exit;
        if not GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group") then begin
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
            GeneralPostingSetup.SuggestSetupAccounts();
            GeneralPostingSetup.Modify(true);
        end;
    end;

    [RequestPageHandler]
    procedure EXRFixedAssetProjectedHandler(var EXRFixedAssetProjected: TestRequestPage "EXR Fixed Asset Projected")
    var
        DepreciationBookCode: Code[10];
        FirstDeprDate: Date;
        LastDeprDate: Date;
        UseAccountingPeriod: Boolean;
    begin
        DepreciationBookCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, 10);
        FirstDeprDate := LibraryVariableStorage.DequeueDate();
        LastDeprDate := LibraryVariableStorage.DequeueDate();
        UseAccountingPeriod := LibraryVariableStorage.DequeueBoolean();

        EXRFixedAssetProjected.DepreciationBookCodeField.SetValue(DepreciationBookCode);
        EXRFixedAssetProjected.FirstDepreciationDateField.SetValue(FirstDeprDate);
        EXRFixedAssetProjected.SecondDepreciationDateField.SetValue(LastDeprDate);
        EXRFixedAssetProjected.UseAccountingPeriodField.SetValue(UseAccountingPeriod);
        EXRFixedAssetProjected.OK().Invoke();
    end;

}