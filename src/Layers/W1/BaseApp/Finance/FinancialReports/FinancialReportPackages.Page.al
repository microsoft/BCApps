// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Threading;

page 8371 "Financial Report Packages"
{
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Packages';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Financial Report Package";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                    ShowMandatory = true;
                }
                field(Name; Rec.Description) { }
                field(Description; Rec.InternalDescription) { }
                field("No. of Schedules"; Rec."No. of Schedules") { }
            }
            part(ReportsPart; "Fin. Report Package Reports")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reports';
                Editable = ReportsPartEditable;
                SubPageLink = "Package Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Print)
            {
                Caption = 'Print';
                Enabled = Rec.Code <> '';
                Image = Print;
                Scope = Repeater;
                ToolTip = 'Print the financial report package. This will generate a PDF that combines all the financial reports defined in the package.';

                trigger OnAction()
                var
                    FinReportPackageReport: Record "Fin. Report Package Report";
                    AccountSchedule: Report "Account Schedule";
                    FinancialReportExportJob: Codeunit "Financial Report Export Job";
                    AccScheduleParam: Text;
                    IsHandled: Boolean;
                begin
                    FinReportPackageReport.SetAutoCalcFields("Report Parameters");
                    FinReportPackageReport.SetRange("Package Code", Rec.Code);
                    FinReportPackageReport.FindSet();
                    AccScheduleParam := FinancialReportExportJob.InitAccSchFromPackageReport(AccountSchedule, FinReportPackageReport);
                    if FinReportPackageReport.Next() <> 0 then
                        repeat
                            AccountSchedule.AddPackageReportToAppend(FinReportPackageReport);
                        until FinReportPackageReport.Next() = 0;
                    OnBeforePrintAccountSchedule(Rec, AccountSchedule, AccScheduleParam, IsHandled);
                    if not IsHandled then
                        AccountSchedule.Print(AccScheduleParam);
                end;
            }
        }
        area(Navigation)
        {
            action(Schedules)
            {
                Caption = 'Schedules';
                Image = Calendar;
                RunObject = page "Fin. Report Package Schedules";
                RunPageLink = "Package Code" = field(Code);
                RunPageMode = Edit;
                ToolTip = 'View or edit the schedules for this financial report package.';
            }
            action(JobQueueEntry)
            {
                Caption = 'Job Queue Entry';
                Image = JobListSetup;
                RunObject = page "Job Queue Entry Card";
                RunPageLink = "Object Type to Run" = const(Codeunit),
                              "Object ID to Run" = const(Codeunit::"Financial Report Export Job");
                RunPageMode = Edit;
                ToolTip = 'View or edit the job queue entry that is used to export and email financial report packages on a regular basis.';

                trigger OnAction()
                var
                    FinancialReportExport: Codeunit "Financial Report Export";
                begin
                    FinancialReportExport.ScheduleJob();
                end;
            }
            action(Logs)
            {
                Caption = 'Logs';
                Image = Log;
                RunObject = page "Fin. Rep. Package Export Logs";
                RunPageLink = "Package Code" = field(Code);
                RunPageMode = View;
                ToolTip = 'View the export logs for this financial report package.';
            }
        }
        area(Promoted)
        {
            actionref(Print_Promoted; Print) { }
            actionref(Schedules_Promoted; Schedules) { }
            actionref(JobQueueEntry_Promoted; JobQueueEntry) { }
            actionref(Logs_Promoted; Logs) { }
        }
    }

    var
        ReportsPartEditable: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        ReportsPartEditable := Rec.Code <> '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        ReportsPartEditable := Rec.Code <> '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintAccountSchedule(var FinancialReportPackage: Record "Financial Report Package"; var AccountSchedule: Report "Account Schedule"; var AccScheduleParam: Text; var IsHandled: Boolean)
    begin
    end;
}