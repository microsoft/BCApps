// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 8373 "Fin. Report Package Schedule"
{
    Caption = 'Financial Report Package Schedule';
    DataClassification = CustomerContent;
    DrillDownPageId = "Fin. Report Package Schedules";
    LookupPageId = "Fin. Report Package Schedules";

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Financial Report Package".Code;
            ToolTip = 'Specifies the financial report package code associated with this schedule.';
            DataClassification = CustomerContent;
        }
        field(2; "Schedule Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the unique code for the financial report package schedule.';
            DataClassification = CustomerContent;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of this schedule.';
            DataClassification = CustomerContent;
        }
        field(4; "Send Email"; Boolean)
        {
            Caption = 'Send Email';
            ToolTip = 'Specifies if the reports from this schedule will be sent to the recipients via email. You can specify who will receive the emails in financial report package recipients.';
            DataClassification = CustomerContent;
        }
        field(5; "Next Run Date/Time"; DateTime)
        {
            Caption = 'Next Run Date/Time';
            ToolTip = 'Specifies the next date and time this schedule will run.';
            DataClassification = SystemMetadata;
        }
        field(6; "Recurrence Run Date Formula"; DateFormula)
        {
            Caption = 'Recurrence Run Date Formula';
            ToolTip = 'Specifies the date formula that is used to calculate the next time this schedule will run. For example use CM+1M to run the report at the end of every month.';

        }
        field(7; "Expiration Date/Time"; DateTime)
        {
            Caption = 'Expiration Date/Time';
            ToolTip = 'Specifies the date and time when the schedule is to expire, after which the schedule will not be run.';
            DataClassification = CustomerContent;
        }
        field(8; "No. of Recipients"; Integer)
        {
            CalcFormula = count("Fin. Report Package Recipient" where("Package Code" = field("Package Code"), "Schedule Code" = field("Schedule Code")));
            Caption = 'No. of Recipients';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of recipients that will receive this schedule of reports.';
        }
    }

    keys
    {
        key(PK; "Package Code", "Schedule Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        FinReportPackageRecipient: Record "Fin. Report Package Recipient";
        FinRepPackageExportLog: Record "Fin. Rep. Package Export Log";
    begin
        FinReportPackageRecipient.SetRange("Package Code", "Package Code");
        FinReportPackageRecipient.SetRange("Schedule Code", "Schedule Code");
        FinReportPackageRecipient.DeleteAll(true);

        FinRepPackageExportLog.SetRange("Package Code", "Package Code");
        FinRepPackageExportLog.SetRange("Schedule Code", "Schedule Code");
        FinRepPackageExportLog.DeleteAll(true);
    end;

    procedure CalcNextRunDate()
    var
        BlankDateFormula: DateFormula;
    begin
        if ("Recurrence Run Date Formula" = BlankDateFormula) or (
                (CurrentDateTime() > "Expiration Date/Time") and
                ("Expiration Date/Time" <> 0DT))
        then
            "Next Run Date/Time" := 0DT
        else
            "Next Run Date/Time" := CreateDateTime(CalcDate("Recurrence Run Date Formula", Today()), "Next Run Date/Time".Time());
    end;
}