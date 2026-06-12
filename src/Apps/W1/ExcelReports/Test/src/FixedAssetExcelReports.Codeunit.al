// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports.Test;

using Microsoft.Finance.ExcelReports;
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

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
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

    [Test]
    [HandlerFunctions('EXRFixedAssetProjectedHandler')]
    procedure ProjectedValueDeclBalShouldUseCorrectBookValueAcrossFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalTemplate: Record "FA Journal Template";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        AcquisitionAmount: Decimal;
        BookValueAfterDepr: Decimal;
        DecliningBalancePct: Decimal;
        ExpectedProjectedDepr: Decimal;
        MonthlyDeprAmount: Decimal;
        ReportAmount: Decimal;
        I: Integer;
        AcquisitionDate: Date;
        BasePostingDate: Date;
        DeprStartDate: Date;
        FirstReportDeprDate: Date;
        FiscalYearStartDate: Date;
        LastReportDeprDate: Date;
        PostingDate: Date;
        Variant: Variant;
    begin
        // [SCENARIO 631253] Report 4413 "Fixed Asset Projected Value (Excel)" should calculate depreciation
        // using the last posted month's book value when crossing a fiscal year boundary with Declining-Balance 1.
        // Previously it incorrectly used the penultimate month's book value.
        Initialize();

        // [GIVEN] Create Accounting periods with fiscal year.
        CleanupFixedAssetData();
        AccountingPeriod.DeleteAll();
        FiscalYearStartDate := DMY2Date(1, 9, 2025);
        CreateMonthlyAccountingPeriods(FiscalYearStartDate, 24);

        // [GIVEN] Create a depreciation book.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        ModifyDepreciationBook(DepreciationBook);

        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        SetupFAJournalSetup(FAJournalSetup);

        // [GIVEN] Create a fixed asset with Declining-Balance 1 and randomized amount/% values.
        AcquisitionDate := DMY2Date(1, 1, 2025);
        DeprStartDate := AcquisitionDate;
        AcquisitionAmount := 10000 + Round(LibraryRandom.RandDec(90000, 0), 1);
        DecliningBalancePct := 10 + Round(LibraryRandom.RandDec(20, 0), 1);

        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", DeprStartDate);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        FADepreciationBook.Validate("Declining-Balance %", DecliningBalancePct);
        FADepreciationBook.Modify(true);

        // [GIVEN] Post acquisition on the randomized acquisition date.
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        CreateAndPostFAJournalLine(
            FAJournalTemplate.Name, FixedAsset."No.", AcquisitionDate,
            "FA Journal Line FA Posting Type"::"Acquisition Cost",
            DepreciationBook.Code, AcquisitionAmount, FixedAsset."No.");

        // [GIVEN] Post depreciation starting from the acquisition month.
        BasePostingDate := CalcDate('<CM>', AcquisitionDate);
        BookValueAfterDepr := AcquisitionAmount;
        for I := 1 to 8 do begin
            MonthlyDeprAmount := Round(BookValueAfterDepr * DecliningBalancePct / 100 / 12, 1);
            PostingDate := CalcDate('<' + Format(I - 1) + 'M>', BasePostingDate);

            CreateAndPostFAJournalLine(
                FAJournalTemplate.Name, FixedAsset."No.", PostingDate,
                "FA Journal Line FA Posting Type"::Depreciation,
                DepreciationBook.Code, -MonthlyDeprAmount, CopyStr(FixedAsset."No." + '-' + Format(I), 1, MaxStrLen(FixedAsset."No.")));

            BookValueAfterDepr -= MonthlyDeprAmount;
        end;

        // The next projected month should be based on this closing book value.
        ExpectedProjectedDepr := -Round(BookValueAfterDepr * DecliningBalancePct / 100 / 12, 1);
        Commit();

        // [WHEN] Running the Fixed Asset Projected Value (Excel) report.
        FirstReportDeprDate := CalcDate('<CM>', CalcDate('<8M>', BasePostingDate));
        LastReportDeprDate := CalcDate('<11M>', FirstReportDeprDate);
        RunFixedAssetProjectedReport(DepreciationBook.Code, FirstReportDeprDate, LastReportDeprDate, false);

        // [THEN] Verify the projected depreciation in the first projected month uses the latest closing book value.
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="FixedAssetLedgerEntries"]');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Amount', Variant);
        ReportAmount := Variant;
        ReportAmount := Round(ReportAmount, 1);
        Assert.AreEqual(ExpectedProjectedDepr, ReportAmount, ProjectedDeprMismatchLbl);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Fixed Asset Excel Reports");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Fixed Asset Excel Reports");

        EnsureGeneralPostingSetup();
        LibrarySetupStorage.Save(Database::"FA Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Fixed Asset Excel Reports");
    end;

    local procedure CleanupFixedAssetData()
    var
        FAPostingType: Record "FA Posting Type";
        FixedAsset: Record "Fixed Asset";
    begin
        FAPostingType.DeleteAll();
        FixedAsset.DeleteAll();
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
        DefaultFAJournalSetup.FindFirst();
        FAJournalSetup.TransferFields(DefaultFAJournalSetup, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateAndPostFAJournalLine(FAJournalTemplateName: Code[10]; FANo: Code[20]; PostingDate: Date; FAPostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; Amount: Decimal; DocumentNo: Code[20])
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplateName);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalTemplateName, FAJournalBatch.Name);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate("FA Posting Date", PostingDate);
        FAJournalLine.Validate("Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Document No.", DocumentNo);
        FAJournalLine.Modify(true);

        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure RunFixedAssetProjectedReport(DepreciationBookCode: Code[10]; FirstDeprDate: Date; LastDeprDate: Date; UseAccountingPeriod: Boolean)
    var
        Variant: Variant;
        RequestPageXml: Text;
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        LibraryVariableStorage.Enqueue(FirstDeprDate);
        LibraryVariableStorage.Enqueue(LastDeprDate);
        LibraryVariableStorage.Enqueue(UseAccountingPeriod);
        RequestPageXml := Report.RunRequestPage(Report::"EXR Fixed Asset Projected", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Fixed Asset Projected", Variant, RequestPageXml);
    end;

    local procedure EnsureGeneralPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        if not GeneralPostingSetup.IsEmpty() then
            exit;

        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
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

    local procedure ModifyDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        DepreciationBook.Validate("G/L Integration - Acq. Cost", false);
        DepreciationBook.Validate("G/L Integration - Depreciation", false);
        DepreciationBook.Modify(true);
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