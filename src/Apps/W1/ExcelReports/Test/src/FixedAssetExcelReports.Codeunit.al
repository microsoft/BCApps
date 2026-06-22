// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports.Test;

using Microsoft.Finance.ExcelReports;
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
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ProjectedDeprErr: Label 'Projected depreciation must use the last posted month''s book value.';

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
    [HandlerFunctions('FixedAssetProjectedRequestPageHandler')]
    procedure ProjectedValueAcrossFiscalYearUsesLastPostedBookValue()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalTemplate: Record "FA Journal Template";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        Acquisition: Decimal;
        BookValue: Decimal;
        DepreciationPct: Decimal;
        MonthlyDepreciation: Decimal;
        ReportAmount: Decimal;
        Month: Integer;
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO 636726] Report 4413 must project the new fiscal year's first month from the last posted month's book value (Declining-Balance 1).
        CleanupFixedAssetData();
        CreateMonthlyFiscalYears(20240901D, 2);

        // [GIVEN] Create a default depreciation book without G/L integration.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", false);
        DepreciationBook.Validate("G/L Integration - Depreciation", false);
        DepreciationBook.Modify(true);
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        CopyDefaultFAJournalSetup(FAJournalSetup);
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);

        // [GIVEN] Create a Declining-Balance 1 fixed asset acquired at the start of the fiscal year.
        Acquisition := 10000 + Round(LibraryRandom.RandDec(90000, 0), 1);
        DepreciationPct := 10 + Round(LibraryRandom.RandDec(20, 0), 1);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", 20240901D);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"Declining-Balance 1");
        FADepreciationBook.Validate("Declining-Balance %", DepreciationPct);
        FADepreciationBook.Modify(true);
        PostFAJournalLine(FAJournalTemplate.Name, FixedAsset."No.", 20240901D, "FA Journal Line FA Posting Type"::"Acquisition Cost", DepreciationBook.Code, Acquisition);

        // [GIVEN] Depreciation posted for every month of the fiscal year, ending on the fiscal year-end.
        BookValue := Acquisition;
        for Month := 0 to 11 do begin
            MonthlyDepreciation := Round(BookValue * DepreciationPct / 100 / 12, 0.01);
            PostFAJournalLine(
                FAJournalTemplate.Name, FixedAsset."No.", CalcDate('<CM>', CalcDate('<' + Format(Month) + 'M>', 20240901D)),
                "FA Journal Line FA Posting Type"::Depreciation, DepreciationBook.Code, -MonthlyDepreciation);
            BookValue -= MonthlyDepreciation;
        end;
        Commit();

        // [WHEN] Projecting the first month of the next fiscal year, using end-of-month dates for a full period.
        LibraryVariableStorage.Enqueue(DepreciationBook.Code);
        LibraryVariableStorage.Enqueue(20250930D);
        LibraryVariableStorage.Enqueue(20250930D);
        RequestPageXml := Report.RunRequestPage(Report::"EXR Fixed Asset Projected", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Fixed Asset Projected", Variant, RequestPageXml);

        // [THEN] The projected depreciation is based on the last posted book value, not the penultimate month's.
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="FixedAssetLedgerEntries"]');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Amount', Variant);
        ReportAmount := Variant;
        Assert.AreEqual(-Round(BookValue * DepreciationPct / 100 / 12, 0.01), Round(ReportAmount, 0.01), ProjectedDeprErr);
    end;

    local procedure CleanupFixedAssetData()
    var
        FAPostingType: Record "FA Posting Type";
        FixedAsset: Record "Fixed Asset";
    begin
        FAPostingType.DeleteAll();
        FixedAsset.DeleteAll();
    end;

    local procedure CreateMonthlyFiscalYears(FirstFiscalYearStart: Date; NumberOfYears: Integer)
    var
        AccountingPeriod: Record "Accounting Period";
        Month: Integer;
    begin
        AccountingPeriod.DeleteAll();
        for Month := 0 to (12 * NumberOfYears) - 1 do begin
            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := CalcDate('<' + Format(Month) + 'M>', FirstFiscalYearStart);
            AccountingPeriod."New Fiscal Year" := (Month mod 12) = 0;
            AccountingPeriod.Insert();
        end;
    end;

    local procedure CopyDefaultFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        DefaultFAJournalSetup: Record "FA Journal Setup";
    begin
        DefaultFAJournalSetup.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        DefaultFAJournalSetup.FindFirst();
        FAJournalSetup.TransferFields(DefaultFAJournalSetup, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure PostFAJournalLine(TemplateName: Code[10]; FANo: Code[20]; PostingDate: Date; PostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; Amount: Decimal)
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, TemplateName);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, TemplateName, FAJournalBatch.Name);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate("FA Posting Date", PostingDate);
        FAJournalLine.Validate("Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Type", PostingType);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Document No.", CopyStr(FANo + Format(PostingDate, 0, '<Year4><Month,2>'), 1, 20));
        FAJournalLine.Modify(true);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
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

    [RequestPageHandler]
    procedure FixedAssetProjectedRequestPageHandler(var EXRFixedAssetProjected: TestRequestPage "EXR Fixed Asset Projected")
    begin
        EXRFixedAssetProjected.DepreciationBookCodeField.SetValue(LibraryVariableStorage.DequeueText());
        EXRFixedAssetProjected.FirstDepreciationDateField.SetValue(LibraryVariableStorage.DequeueDate());
        EXRFixedAssetProjected.SecondDepreciationDateField.SetValue(LibraryVariableStorage.DequeueDate());
        EXRFixedAssetProjected.UseAccountingPeriodField.SetValue(true);
        EXRFixedAssetProjected.OK().Invoke();
    end;

}
