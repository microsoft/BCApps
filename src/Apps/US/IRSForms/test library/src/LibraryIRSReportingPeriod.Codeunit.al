// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Environment;
using System.Utilities;

codeunit 148000 "Library IRS Reporting Period"
{
    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        NoAvailableReportingYearErr: Label 'There is no unused reporting year between %1 and 3000.', Comment = '%1 = first reporting year';

    procedure CreateOneDayReportingPeriod(ReportingDate: Date): Code[20]
    begin
        exit(CreateReportingPeriod(ReportingDate, ReportingDate));
    end;

    procedure CreateReportingPeriod(StartingDate: Date; EndingDate: Date): Code[20]
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", StartingDate);
        IRSReportingPeriod.Validate("Ending Date", EndingDate);
        IRSReportingPeriod.Insert(true);
        exit(IRSReportingPeriod."No.");
    end;

    procedure CreateSpecificReportingPeriod(PeriodNo: Code[20]; StartingDate: Date; EndingDate: Date)
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        IRSReportingPeriod."No." := PeriodNo;
        IRSReportingPeriod.Validate("Starting Date", StartingDate);
        IRSReportingPeriod.Validate("Ending Date", EndingDate);
        IRSReportingPeriod.Insert(true);
    end;

    procedure CreateAvailableAnnualReportingPeriod(FirstReportingYear: Integer): Code[20]
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        TempReportingYear: Record Integer temporary;
        PeriodNo: Code[20];
        ReportingYear: Integer;
        StartingDate: Date;
        EndingDate: Date;
        PeriodNoAvailable: Boolean;
    begin
        for ReportingYear := FirstReportingYear to 3000 do begin
            PeriodNo := Format(ReportingYear, 0, 9);
            StartingDate := DMY2Date(1, 1, ReportingYear);
            EndingDate := DMY2Date(31, 12, ReportingYear);
            IRSReportingPeriod.Reset();
            IRSReportingPeriod.SetRange("No.", PeriodNo);
            PeriodNoAvailable := IRSReportingPeriod.IsEmpty();
            IRSReportingPeriod.SetRange("No.");
            IRSReportingPeriod.SetFilter("Starting Date", '<=%1', EndingDate);
            IRSReportingPeriod.SetFilter("Ending Date", '>=%1', StartingDate);
            DocHeader.SetRange("Period No.", PeriodNo);
            TempReportingYear.Number := ReportingYear;
            TempReportingYear.Insert();
            TempReportingYear.Mark(PeriodNoAvailable and IRSReportingPeriod.IsEmpty() and DocHeader.IsEmpty());
        end;
        TempReportingYear.MarkedOnly(true);
        Assert.IsFalse(TempReportingYear.IsEmpty(), StrSubstNo(NoAvailableReportingYearErr, FirstReportingYear));
        TempReportingYear.FindFirst();
        ReportingYear := TempReportingYear.Number;
        PeriodNo := Format(ReportingYear, 0, 9);
        CreateSpecificReportingPeriod(PeriodNo, DMY2Date(1, 1, ReportingYear), DMY2Date(31, 12, ReportingYear));
        exit(PeriodNo);
    end;

    procedure GetReportingPeriod(PostingDate: Date): Code[20]
    begin
        exit(GetReportingPeriod(PostingDate, PostingDate));
    end;

    procedure GetReportingPeriod(StartingDate: Date; EndingDate: Date): Code[20]
    var
        IRSReportingPeriod: Codeunit "IRS Reporting Period";
    begin
        exit(IRSReportingPeriod.GetReportingPeriod(StartingDate, EndingDate));
    end;

    procedure RemoveAllReportingPeriodsWithRelatedData()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        IRSReportingPeriod.DeleteAll(true);
    end;

    procedure GetPostingDate(): Date
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Posting Date", "G/L Account No.", "Dimension Set ID");
        if GLEntry.FindLast() then
            exit(CalcDate('<1Y>', GLEntry."Posting Date"));
        exit(WorkDate());
    end;

    /// <summary>
    /// Copies IRS reporting period setup from one period to another.
    /// </summary>
    procedure CopyPeriodSetup(FromPeriodNo: Code[20]; ToPeriodNo: Code[20])
    var
        IRSReportingPeriod: Codeunit "IRS Reporting Period";
    begin
        IRSReportingPeriod.CopyReportingPeriodSetup(FromPeriodNo, ToPeriodNo);
    end;

    [TryFunction]
    procedure TryCopyPeriodSetup(FromPeriodNo: Code[20]; ToPeriodNo: Code[20])
    begin
        CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
    end;

    procedure CopyPeriodSetup(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; var TempSelectedCompany: Record Company temporary)
    var
        IRSReportingPeriod: Codeunit "IRS Reporting Period";
    begin
        IRSReportingPeriod.CopyReportingPeriodSetup(FromPeriodNo, ToPeriodNo, TempSelectedCompany);
    end;

    procedure UpdateAnnualSetup(PeriodNo: Code[20]; TargetCompany: Text): Text
    var
        IRSFormsData: Codeunit "IRS Forms Data";
        Details: Text;
    begin
        IRSFormsData.UpdateAnnualSetup(PeriodNo, TargetCompany, Details);
        exit(Details);
    end;

    procedure UpdateDataForNewTaxYear(FromPeriodNo: Code[20]; ToPeriodNo: Code[20])
    var
        IRSReportingPeriod: Codeunit "IRS Reporting Period";
    begin
        IRSReportingPeriod.UpdateDataForNewTaxYear(FromPeriodNo, ToPeriodNo, false);
    end;
}
