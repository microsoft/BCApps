// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.EServices.EDocument;
using System.Email;

page 8362 "Financial Report Export Logs"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Export Logs';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Financial Report Export Log";
    SourceTableView = order(descending);
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Financial Report Name"; Rec."Financial Report Name") { }
                field("Financial Report Schedule Code"; Rec."Financial Report Schedule Code") { }
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
                    SentEmails.SetRelatedRecord(Database::"Financial Report Export Log", Rec.SystemId);
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