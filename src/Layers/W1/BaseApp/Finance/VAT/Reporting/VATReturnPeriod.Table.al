// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using System.Utilities;

/// <summary>
/// Manages VAT return periods with deadlines, status tracking, and associated VAT return document links.
/// Controls the periodic VAT reporting cycle and provides automated period management capabilities.
/// </summary>
table 737 "VAT Return Period"
{
    Caption = 'VAT Return Period';
    LookupPageID = "VAT Return Period List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the VAT return period assigned from number series.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        /// <summary>
        /// Number series used for generating VAT return period numbers.
        /// </summary>
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        /// <summary>
        /// Period key identifier used for matching with tax authority period data.
        /// </summary>
        field(3; "Period Key"; Code[10])
        {
            Caption = 'Period Key';
        }
        /// <summary>
        /// Starting date of the VAT return period for transaction inclusion.
        /// </summary>
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
            ToolTip = 'Specifies the start date of the VAT return period.';
        }
        /// <summary>
        /// Ending date of the VAT return period for transaction inclusion.
        /// </summary>
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';
            ToolTip = 'Specifies the end date of the VAT return period.';
        }
        /// <summary>
        /// Due date for submitting the VAT return to tax authorities.
        /// </summary>
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the due date for the VAT return period.';
        }
        /// <summary>
        /// Current status of the VAT return period indicating processing stage.
        /// </summary>
        field(7; Status; Option)
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the VAT return period.';
            OptionCaption = 'Open,Closed';
            OptionMembers = Open,Closed;
        }
        /// <summary>
        /// Date when the VAT return period information was received from tax authorities.
        /// </summary>
        field(8; "Received Date"; Date)
        {
            Caption = 'Received Date';
            ToolTip = 'Specifies the VAT return period received date.';
        }
        /// <summary>
        /// Number of the associated VAT return document created for this period.
        /// </summary>
        field(20; "VAT Return No."; Code[20])
        {
            Caption = 'VAT Return No.';
            ToolTip = 'Specifies the number of the associated VAT return.';
            Editable = false;
            TableRelation = if ("VAT Return No." = filter(<> '')) "VAT Report Header"."No." where("VAT Report Config. Code" = const("VAT Return"),
                                                                                                "No." = field("VAT Return No."));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                Rec.DrillDownVATReturn();
            end;
        }
        /// <summary>
        /// Current status of the associated VAT return document from VAT Report Header.
        /// </summary>
        field(21; "VAT Return Status"; Enum "VAT Return Status")
        {
            CalcFormula = lookup("VAT Report Header".Status where("VAT Report Config. Code" = const("VAT Return"),
                                                                   "No." = field("VAT Return No.")));
            Caption = 'VAT Return Status';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        if VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", "VAT Return No.") then
            Error(DeleteExistingVATRetErr);
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := GetNoSeriesCode();
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportSetupGot: Boolean;

        DeleteExistingVATRetErr: Label 'You cannot delete a VAT return period that has a linked VAT return.';
        OverdueTxt: Label 'Your VAT return is overdue since %1 (%2 days)', Comment = '%1 - date; %2 - days count';
        OpenTxt: Label 'Your VAT return is due %1 (in %2 days)', Comment = '%1 - date; %2 - days count';

    local procedure GetNoSeriesCode(): Code[20]
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.TestField("VAT Return Period No. Series");
        exit(VATReportSetup."VAT Return Period No. Series");
    end;

    /// <summary>
    /// Copies VAT return period information to a VAT report header.
    /// Sets period dates, year, and number for VAT return creation.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header to populate with period data</param>
    procedure CopyToVATReturn(var VATReportHeader: Record "VAT Report Header")
    begin
        TestField("Start Date");
        TestField("End Date");
        VATReportHeader."Return Period No." := "No.";
        VATReportHeader."Period Year" := Date2DMY("End Date", 3);
        VATReportHeader."Start Date" := "Start Date";
        VATReportHeader."End Date" := "End Date";
        ParseDatePeriod(VATReportHeader);
    end;

    local procedure ParseDatePeriod(var VATReportHeader: Record "VAT Report Header")
    var
        Date: Record Date;
    begin
        Date.SetRange("Period Start", VATReportHeader."Start Date");
        Date.SetRange("Period End", ClosingDate(VATReportHeader."End Date"));
        if Date.FindFirst() then begin
            case Date."Period Type" of
                Date."Period Type"::Month:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Month;
                Date."Period Type"::Quarter:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Quarter;
                Date."Period Type"::Year:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Year;
            end;
            VATReportHeader."Period No." := Date."Period No.";
        end else begin
            VATReportHeader."Period Type" := VATReportHeader."Period Type"::" ";
            VATReportHeader."Period No." := 0;
        end;
    end;

    /// <summary>
    /// Finds VAT period containing the specified reporting date.
    /// Filters by start and end date range.
    /// </summary>
    /// <param name="VATReportingDate">Date to search for within VAT periods</param>
    /// <returns>True if a VAT period contains the specified date</returns>
    internal procedure FindVATPeriodByDate(VATReportingDate: Date): Boolean
    begin
        Rec.SetFilter("End Date", '>=%1', VATReportingDate);
        Rec.SetFilter("Start Date", '<=%1', VATReportingDate);
        exit(Rec.FindFirst());
    end;

    /// <summary>
    /// Finds VAT return period matching the specified start and end dates.
    /// Used to locate existing periods for validation and processing.
    /// </summary>
    /// <param name="VATReturnPeriod">VAT return period record to populate if found</param>
    /// <param name="StartDate">Period start date to match</param>
    /// <param name="EndDate">Period end date to match</param>
    /// <returns>True if matching VAT return period is found</returns>
    procedure FindVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"; StartDate: Date; EndDate: Date): Boolean
    begin
        VATReturnPeriod.SetRange("Start Date", StartDate);
        VATReturnPeriod.SetRange("End Date", EndDate);
        exit(VATReturnPeriod.FindFirst());
    end;

    /// <summary>
    /// Compares current period with another VAT return period for differences.
    /// Checks due date, status, received date, and period key for changes.
    /// </summary>
    /// <param name="VATReturnPeriod">VAT return period to compare against</param>
    /// <returns>True if periods have different values in key fields</returns>
    procedure DiffersFromVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"): Boolean
    begin
        exit(
          ("Due Date" <> VATReturnPeriod."Due Date") or
          (Status <> VATReturnPeriod.Status) or
          ("Received Date" <> VATReturnPeriod."Received Date") or
          ("Period Key" <> VATReturnPeriod."Period Key"));
    end;

    /// <summary>
    /// Opens VAT return card for the current period.
    /// Creates new VAT return if none exists for open periods.
    /// </summary>
    procedure DrillDownVATReturn()
    var
        VATReportMgt: Codeunit "VAT Report Mgt.";
    begin
        if (Status = Status::Open) or ("VAT Return No." <> '') then
            VATReportMgt.OpenVATReturnCardFromVATPeriod(Rec);
    end;

    local procedure GetVATReportSetup()
    begin
        if VATReportSetupGot then
            exit;

        VATReportSetup.Get();
        VATReportSetupGot := true;
    end;

    /// <summary>
    /// Calculates and returns status text for open or overdue VAT periods.
    /// Provides due date warnings and overdue notifications based on setup.
    /// </summary>
    /// <returns>Formatted text indicating period status and days until/since due date</returns>
    procedure CheckOpenOrOverdue(): Text
    begin
        GetVATReportSetup();
        if (Status = Status::Open) and ("Due Date" <> 0D) then
            case true of
                // Overdue
                ("Due Date" < WorkDate()):
                    exit(StrSubstNo(OverdueTxt, "Due Date", WorkDate() - "Due Date"));
                // Open
                VATReportSetup.IsPeriodReminderCalculation() and
              ("Due Date" >= WorkDate()) and
              ("Due Date" <= CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate())):
                    exit(StrSubstNo(OpenTxt, "Due Date", "Due Date" - WorkDate()));
            end;
    end;
}
