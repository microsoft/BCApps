// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

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
            TempReportingYear.Number := ReportingYear;
            TempReportingYear.Insert();
            TempReportingYear.Mark(PeriodNoAvailable and IRSReportingPeriod.IsEmpty() and not HasAnnualReportingReferences(PeriodNo));
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
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        FormInstruction: Record "IRS 1099 Form Instruction";
        StatementLine: Record "IRS 1099 Form Statement Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
        DocLineDetail: Record "IRS 1099 Form Doc. Line Detail";
        DocSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        FormReport: Record "IRS 1099 Form Report";
        EmailQueue: Record "IRS 1099 Email Queue";
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        VendorAdjustment: Record "IRS 1099 Vendor Form Box Adj.";
        Transmission: Record "Transmission IRIS";
        TransmissionLog: Record "Transmission Log IRIS";
        TransmissionLogLine: Record "Transmission Log Line IRIS";
        ErrorInformation: Record "Error Information IRIS";
    begin
        TransmissionLogLine.DeleteAll(true);
        TransmissionLog.DeleteAll(true);
        Transmission.ModifyAll(Status, Enum::"Transmission Status IRIS"::None);
        Transmission.DeleteAll(true);
        ErrorInformation.DeleteAll(true);
        DocHeader.ModifyAll(Status, DocHeader.Status::Open);
        DocHeader.ModifyAll("IRIS Transmission Document ID", 0);
        DocHeader.DeleteAll(true);
        DocLine.DeleteAll(true);
        DocLineDetail.DeleteAll(true);
        DocSupplementalLine.DeleteAll(true);
        FormReport.DeleteAll(true);
        EmailQueue.DeleteAll(true);
        IRSReportingPeriod.DeleteAll(true);
        // Earlier triggerless deletions can leave setup without its parent period.
        Form.DeleteAll(true);
        StatementLine.DeleteAll(true);
        SupplementalBox.DeleteAll(true);
        FormBox.DeleteAll(true);
        FormInstruction.DeleteAll(true);
        VendorSetup.DeleteAll(true);
        VendorAdjustment.DeleteAll(true);
    end;

    procedure GetPostingDate(): Date
    begin
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

    local procedure HasAnnualReportingReferences(PeriodNo: Code[20]): Boolean
    var
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        FormInstruction: Record "IRS 1099 Form Instruction";
        StatementLine: Record "IRS 1099 Form Statement Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        VendorAdjustment: Record "IRS 1099 Vendor Form Box Adj.";
        Transmission: Record "Transmission IRIS";
    begin
        Form.SetRange("Period No.", PeriodNo);
        FormBox.SetRange("Period No.", PeriodNo);
        FormInstruction.SetRange("Period No.", PeriodNo);
        StatementLine.SetRange("Period No.", PeriodNo);
        SupplementalBox.SetRange("Period No.", PeriodNo);
        DocHeader.SetRange("Period No.", PeriodNo);
        DocLine.SetRange("Period No.", PeriodNo);
        VendorSetup.SetRange("Period No.", PeriodNo);
        VendorAdjustment.SetRange("Period No.", PeriodNo);
        Transmission.SetRange("Period No.", PeriodNo);
        exit(not Form.IsEmpty() or not FormBox.IsEmpty() or not FormInstruction.IsEmpty() or
            not StatementLine.IsEmpty() or not SupplementalBox.IsEmpty() or not DocHeader.IsEmpty() or
            not DocLine.IsEmpty() or not VendorSetup.IsEmpty() or not VendorAdjustment.IsEmpty() or
            not Transmission.IsEmpty());
    end;
}
