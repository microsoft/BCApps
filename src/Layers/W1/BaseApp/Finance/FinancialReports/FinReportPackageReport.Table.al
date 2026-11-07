// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Period;
using System.Utilities;

table 8372 "Fin. Report Package Report"
{
    Caption = 'Financial Report Package Report';
    DataClassification = CustomerContent;
    DrillDownPageId = "Fin. Report Package Reports";
    LookupPageId = "Fin. Report Package Reports";

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Financial Report Package".Code;
            ToolTip = 'Specifies the financial report package code associated with this report.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
            ToolTip = 'Specifies the line number.';
        }
        field(3; "Financial Report Name"; Code[10])
        {
            Caption = 'Financial Report Name';
            NotBlank = true;
            TableRelation = "Financial Report";
            ToolTip = 'Specifies the financial report included in the package.';
        }
        field(4; "Start Date Filter Formula"; DateFormula)
        {
            Caption = 'Start Date Filter Formula';
            ToolTip = 'Specifies the date formula used to calculate the start date of the report filter.';
        }
        field(5; "End Date Filter Formula"; DateFormula)
        {
            Caption = 'End Date Filter Formula';
            ToolTip = 'Specifies the date formula used to calculate the end date of the report filter.';
        }
        field(6; "Report Parameters"; Blob)
        {
            Caption = 'Report Parameters';
            ToolTip = 'Specifies the parameters used when exporting the report.';
        }
        field(7; "Date Filter Period Formula"; Code[20])
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
        field(8; "Date Filter Period Formula LID"; Integer)
        {
            Caption = 'Date Filter Period Formula Lang. ID';
            ToolTip = 'Specifies the period formula language ID.';
        }
        field(9; "Custom Filters"; Boolean)
        {
            Caption = 'Custom Filters';
            ToolTip = 'Specifies if the report will be generated with custom filters. Uncheck this field to clear the custom filters. If not specified, the filters on the financial report definition is used instead.';

            trigger OnValidate()
            var
                ConfirmMgt: Codeunit "Confirm Management";
            begin
                if "Custom Filters" then
                    EditCustomFilters()
                else begin
                    if ConfirmMgt.GetResponseOrDefault(ClearCustomFilterQst, true) then begin
                        Clear("Report Parameters");
                        Modify();
                    end;
                    SetCustomFilters();
                end;
            end;
        }
        field(10; "Report Filters"; Blob)
        {
            Caption = 'Report Filters';
            ToolTip = 'Specifies the filters used when exporting the report.';
        }
    }

    keys
    {
        key(PK; "Package Code", "Line No.")
        {
            Clustered = true;
        }
    }

    var
        ClearCustomFilterQst: Label 'Are you sure you want to clear the custom filters? You will be able to select the check box to edit the custom filters again.';

    trigger OnInsert()
    begin
        TestField("Package Code");
        TestField("Financial Report Name");
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
        "Custom Filters" := "Report Parameters".Length() <> 0;
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