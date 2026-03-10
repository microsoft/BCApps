// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8390 "Financial Report Audit Logs"
{
    AboutText = 'The Financial Report Audit Log page provides a history of changes and actions related to financial reports. It helps track user activities, report definitions, and formats used for auditing purposes.';
    AboutTitle = 'About Financial Report Audit Log';
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Audit Logs';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Financial Report Audit Log";
    SourceTableView = order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Date and Time';
                    Tooltip = 'Specifies the date and time when the report was accessed.';
                }
                field("Report Definition Code"; Rec."Report Name") { }
                field("Report Definition Name"; Rec."Report Description") { }
                field(User; Rec.User) { }
                field(Format; Rec.Format) { }
                field(Scheduled; Rec.Scheduled) { }
            }
        }
    }

    views
    {
        view("Last 30 Days")
        {
            Caption = 'Last 30 Days';
            Filters = where("Date Filter Type" = const(Last30Days));
        }
        view("Year to Date")
        {
            Caption = 'Year to Date';
            Filters = where("Date Filter Type" = const(YearToDate));
        }
    }

    trigger OnOpenPage()
    var
        NewCaption: Text;
    begin
        NewCaption := Caption;
        if Rec.GetFilter("Report Name") <> '' then
            if Rec.GetFilter("Report Name") = Rec.GetRangeMin("Report Name") then
                NewCaption := StrSubstNo('%1 ∙ %2', Caption, Rec.GetFilter("Report Name"));

        if Rec.GetFilter(User) <> '' then
            if Rec.GetFilter(User) = Rec.GetRangeMin(User) then
                NewCaption := StrSubstNo('%1 ∙ %2', NewCaption, Rec.GetFilter(User));

        Caption(NewCaption);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        FinReportAuditLog: Record "Financial Report Audit Log";
    begin
        Rec.SetRange(SystemCreatedAt);
        if Rec.GetFilter("Date Filter Type") <> '' then
            if Evaluate(FinReportAuditLog."Date Filter Type", Rec.GetFilter("Date Filter Type")) then
                case FinReportAuditLog."Date Filter Type" of
                    Rec."Date Filter Type"::Last30Days:
                        Rec.SetRange(SystemCreatedAt, CreateDateTime(CalcDate('<-30D>'), 0T), CreateDateTime(Today, 235959.999T));
                    Rec."Date Filter Type"::YearToDate:
                        Rec.SetRange(SystemCreatedAt, CreateDateTime(CalcDate('<-CY>'), 0T), CreateDateTime(Today, 235959.999T));
                    else
                        OnDateFilterCaseElse(FinReportAuditLog."Date Filter Type", Rec);
                end;

        exit(Rec.Find(Which));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDateFilterCaseElse(DateFilter: Enum "Fin. Rep. Aud. Log Date Filter"; var Rec: Record "Financial Report Audit Log")
    begin
    end;
}