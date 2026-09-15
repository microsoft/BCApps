// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.EServices.EDocument;
using System.Email;

page 8375 "Fin. Rep. Package Export Logs"
{
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Package Export Logs';
    DataCaptionFields = "Package Code", "Schedule Code";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Fin. Rep. Package Export Log";
    SourceTableView = order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Package Code"; Rec."Package Code") { }
                field("Schedule Code"; Rec."Schedule Code") { }
                field("Start Date/Time"; Rec."Start Date/Time") { }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ReportInbox)
            {
                Caption = 'Report Inbox';
                Image = Report;
                ToolTip = 'View the report inbox entries that were created.';

                trigger OnAction()
                var
                    ReportInbox: Record "Report Inbox";
                begin
                    ReportInbox.SetRange("Job Queue Log Entry ID", Rec.SystemId);
                    Page.Run(Page::"Report Inbox", ReportInbox);
                end;
            }
            action(SentEmails)
            {
                Caption = 'Sent Emails';
                Image = Email;
                ToolTip = 'View the emails that were sent.';

                trigger OnAction()
                var
                    SentEmails: Page "Sent Emails";
                begin
                    SentEmails.SetRelatedRecord(Database::"Fin. Rep. Package Export Log", Rec.SystemId);
                    SentEmails.Run();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ReportInbox_Promoted; ReportInbox) { }
            actionref(SentEmails_Promoted; SentEmails) { }
        }
    }
}