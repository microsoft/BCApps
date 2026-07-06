// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Period;
using System.Security.User;
using System.Utilities;

table 8360 "Financial Report Schedule"
{
    Caption = 'Financial Report Schedule';
    DataClassification = CustomerContent;
    LookupPageId = "Financial Report Schedules";
    DrillDownPageId = "Financial Report Schedules";

    fields
    {
        field(1; "Financial Report Name"; Code[10])
        {
            Caption = 'Financial Report Name';
            NotBlank = true;
            TableRelation = "Financial Report";
            ToolTip = 'Specifies the name of the financial report.';
        }
        field(2; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the code of the schedule.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description.';
        }
        field(4; "Export to Excel"; Boolean)
        {
            Caption = 'Export to Excel';
            ToolTip = 'Specifies if the report will be exported to Excel.';
        }
        field(5; "Export to PDF"; Boolean)
        {
            Caption = 'Export to PDF';
            ToolTip = 'Specifies if the report will be exported to PDF.';
        }
        field(6; "Excel Template Code"; Code[20])
        {
            Caption = 'Excel Template Code';
            TableRelation = "Fin. Report Excel Template".Code where("Financial Report Name" = field("Financial Report Name"));
            ToolTip = 'Specifies the Excel template used when exporting to Excel. If not specified, the template on the financial report definition is used instead.';
        }
        field(7; "Send Email"; Boolean)
        {
            Caption = 'Send Email';
            ToolTip = 'Specifies if the exported Excel or PDF file will be sent to users via email. You can specify who will receive the email in Financial Report Recipients.';

            trigger OnValidate()
            begin
                if "Send Email" then begin
                    if not ("Export to Excel" or "Export to PDF") then
                        Error(MustExportAtLeastOneErr);

                    ValidateRecipientEmails();
                end;
            end;
        }
        field(8; "Next Run Date/Time"; DateTime)
        {
            Caption = 'Next Run Date/Time';
            ToolTip = 'Specifies the next date and time this schedule will run.';
        }
        field(9; "Recurrence Run Date Formula"; DateFormula)
        {
            Caption = 'Recurrence Run Date Formula';
            ToolTip = 'Specifies the date formula that is used to calculate the next time this schedule will run. For example use CM+1M to run the report at the end of every month.';
        }
        field(10; "Expiration Date/Time"; DateTime)
        {
            Caption = 'Expiration Date/Time';
            ToolTip = 'Specifies the date and time when the schedule is to expire, after which the schedule will not be run.';
        }
        field(11; "Report Filters"; Blob)
        {
            Caption = 'Report Filters';
            ToolTip = 'Specifies the filters used when exporting this schedule to Excel.';
        }
        field(12; "Report Parameters"; Blob)
        {
            Caption = 'Report Parameters';
            ToolTip = 'Specifies the parameters used when exporting this schedule to PDF.';
        }
        field(13; "Financial Report Row Group"; Code[10])
        {
            Caption = 'Financial Report Row Group';
            TableRelation = "Acc. Schedule Name";
        }
        field(14; "Financial Report Column Group"; Code[10])
        {
            Caption = 'Financial Report Column Group';
            TableRelation = "Column Layout Name";
        }
        field(15; "Start Date Filter Formula"; DateFormula)
        {
            Caption = 'Start Date Filter Formula';
            ToolTip = 'Specifies the date formula used to automatically calculate the start date of the report date filter. If not specified, the value on the financial report definition is used instead.';

            trigger OnValidate()
            begin
                if Format("Start Date Filter Formula") <> '' then begin
                    Clear("Date Filter Period Formula");
                    Clear("Date Filter Period Formula LID");
                end;
            end;
        }
        field(16; "End Date Filter Formula"; DateFormula)
        {
            Caption = 'End Date Filter Formula';
            ToolTip = 'Specifies the date formula used to automatically calculate the end date of the report date filter. If not specified, the value on the financial report definition is used instead.';

            trigger OnValidate()
            begin
                if Format("End Date Filter Formula") <> '' then begin
                    Clear("Date Filter Period Formula");
                    Clear("Date Filter Period Formula LID");
                end;
            end;
        }
        field(17; "Date Filter Period Formula"; Code[20])
        {
            Caption = 'Date Filter Period Formula';
            ToolTip = 'Specifies the period formula used to automatically calculate the report date filter. If not specified, the value on the financial report definition is used instead.';

            trigger OnValidate()
            var
                PeriodFormulaParser: Codeunit "Period Formula Parser";
            begin
                if "Date Filter Period Formula" <> '' then begin
                    PeriodFormulaParser.ValidatePeriodFormula("Date Filter Period Formula", "Date Filter Period Formula LID");
                    Clear("Start Date Filter Formula");
                    Clear("End Date Filter Formula");
                end;
            end;
        }
        field(18; "Date Filter Period Formula LID"; Integer)
        {
            Caption = 'Date Filter Period Formula Lang. ID';
            ToolTip = 'Specifies the period formula language ID.';
        }
        field(19; "No. of Recipients"; Integer)
        {
            CalcFormula = count("Financial Report Recipient" where("Financial Report Name" = field("Financial Report Name"), "Financial Report Schedule Code" = field(Code)));
            Caption = 'No. of Recipients';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of recipients that will receive the financial report.';
        }
        field(20; "Custom Filters"; Boolean)
        {
            Caption = 'Custom Filters';
            ToolTip = 'Specifies if the schedule will export the PDF and Excel reports with custom filters. Uncheck this field to clear the custom filters. If not specified, the filters on the financial report definition is used instead.';

            trigger OnValidate()
            var
                ConfirmMgt: Codeunit "Confirm Management";
            begin
                if "Custom Filters" then
                    EditCustomFilters()
                else begin
                    if ConfirmMgt.GetResponseOrDefault(ClearCustomFilterQst, true) then begin
                        Clear("Report Filters");
                        Clear("Report Parameters");
                        Modify();
                    end;
                    SetCustomFilters();
                end;
            end;
        }
    }

    keys
    {
        key(PK; "Financial Report Name", Code)
        {
            Clustered = true;
        }
        key(NextRunDateTime; "Next Run Date/Time") { }
    }

    trigger OnDelete()
    var
        FinancialReportRecipient: Record "Financial Report Recipient";
        FinancialReportExportLog: Record "Financial Report Export Log";
    begin
        FinancialReportRecipient.SetRange("Financial Report Name", "Financial Report Name");
        FinancialReportRecipient.SetRange("Financial Report Schedule Code", Code);
        FinancialReportRecipient.DeleteAll();

        FinancialReportExportLog.SetRange("Financial Report Name", "Financial Report Name");
        FinancialReportExportLog.SetRange("Financial Report Schedule Code", Code);
        FinancialReportExportLog.DeleteAll();
    end;

    var
        MustExportAtLeastOneErr: Label 'You must specify at least one of the export options, Export to Excel or Export to PDF.';
        RecipientMissingEmailErr: Label 'All recipients must have an email address specified on their User Setup record when enabling Send Email.';
        ClearCustomFilterQst: Label 'Are you sure you want to clear the custom filters? You will be able to select the check box to edit the custom filters again.';

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure ValidateRecipientEmails()
    var
        FinancialReportRecipient: Record "Financial Report Recipient";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        FinancialReportRecipient.SetRange("Financial Report Name", "Financial Report Name");
        FinancialReportRecipient.SetRange("Financial Report Schedule Code", Code);
        if FinancialReportRecipient.FindSet() then
            repeat
                Clear(UserSetup);
                if not UserSetup.Get(FinancialReportRecipient."User ID") then
                    UserSetup."User ID" := FinancialReportRecipient."User ID";
                UserSetup.TestField("E-Mail", ErrorInfo.Create());
            until FinancialReportRecipient.Next() = 0;

        ErrorMessageMgt.CollectErrors(TempErrorMessage);
        if TempErrorMessage.HasErrors(false) then begin
            TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, RecipientMissingEmailErr);
            TempErrorMessage.ShowErrorMessages(true);
        end;
    end;

    procedure CalcNextRunDate()
    var
        BlankDateFormula: DateFormula;
    begin
        if ("Recurrence Run Date Formula" = BlankDateFormula) or
            (
                (CurrentDateTime() > "Expiration Date/Time") and
                ("Expiration Date/Time" <> 0DT)
            )
        then
            "Next Run Date/Time" := 0DT
        else
            "Next Run Date/Time" := CreateDateTime(CalcDate("Recurrence Run Date Formula", Today()), "Next Run Date/Time".Time());
    end;

    procedure EditCustomFilters()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        AccountSchedule: Report "Account Schedule";
        FinReportMgt: Codeunit "Financial Report Mgt.";
        NewReportParameters: Text;
        ReportParameters: Text;
    begin
        ReportParameters := GetReportParameters();
        if ReportParameters = '' then begin
            FinancialReport.Get("Financial Report Name");
            FinReportMgt.SetAccScheduleFilter(FinancialReport, AccountSchedule);
        end;
        AccountSchedule.SetFinancialReportName("Financial Report Name");
        AccountSchedule.SetDateFilterDisabled(true);
        NewReportParameters := AccountSchedule.RunRequestPage(ReportParameters);
        if (NewReportParameters <> '') and (ReportParameters <> NewReportParameters) then begin
            AccountSchedule.GetFilters(AccScheduleLine);
            SetReportFilters(AccScheduleLine.GetView());
            SetReportParameters(NewReportParameters);
            Modify();
        end;
        SetCustomFilters();
    end;

    procedure SetCustomFilters()
    begin
        "Custom Filters" := ("Report Filters".Length() <> 0) or ("Report Parameters".Length() <> 0);
    end;

    procedure GetReportParameters() TextValue: Text
    var
        InStream: InStream;
    begin
        CalcFields("Report Parameters");
        "Report Parameters".CreateInStream(InStream);
        InStream.Read(TextValue);
    end;

    procedure SetReportParameters(TextValue: Text)
    var
        OutStream: OutStream;
    begin
        "Report Parameters".CreateOutStream(OutStream);
        OutStream.Write(TextValue);
    end;

    procedure GetReportFilters() TextValue: Text
    var
        InStream: InStream;
    begin
        CalcFields("Report Filters");
        "Report Filters".CreateInStream(InStream);
        InStream.Read(TextValue);
    end;

    procedure SetReportFilters(TextValue: Text)
    var
        OutStream: OutStream;
    begin
        "Report Filters".CreateOutStream(OutStream);
        OutStream.Write(TextValue);
    end;

}