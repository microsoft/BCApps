// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Manages VAT return periods with deadlines, status tracking, and associated VAT return document links.
/// Controls the periodic VAT reporting cycle and provides automated period management capabilities.
/// </summary>
table 737 "VAT Return Period"
{
    Caption = 'VAT Return Period';
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
        }
        /// <summary>
        /// Current status of the associated VAT return document from VAT Report Header.
        /// </summary>
        field(21; "VAT Return Status"; Option)
        {
            CalcFormula = lookup("VAT Report Header".Status where("No." = field("VAT Return No.")));
            Caption = 'VAT Return Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Released,Submitted';
            OptionMembers = Open,Released,Submitted;
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

    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportSetupGot: Boolean;

        OverdueTxt: Label 'Your VAT return is overdue since %1 (%2 days)', Comment = '%1 - date; %2 - days count';
        OpenTxt: Label 'Your VAT return is due %1 (in %2 days)', Comment = '%1 - date; %2 - days count';

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
