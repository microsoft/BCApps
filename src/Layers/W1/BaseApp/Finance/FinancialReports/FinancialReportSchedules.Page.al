// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8360 "Financial Report Schedules"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Schedules';
    DataCaptionFields = "Financial Report Name";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Financial Report Schedule";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Financial Report Name"; Rec."Financial Report Name")
                {
                    Visible = false;
                }
                field(Code; Rec.Code)
                {
                    ShowMandatory = true;
                }
                field(Description; Rec.Description)
                {
                }
                field("Export to Excel"; Rec."Export to Excel")
                {
                }
                field("Excel Template Code"; Rec."Excel Template Code")
                {
                }
                field("Export to PDF"; Rec."Export to PDF")
                {
                }
                field("Send Email"; Rec."Send Email")
                {
                }
                field("No. of Recipients"; Rec."No. of Recipients")
                {
                }
                field("Next Run Date/Time"; Rec."Next Run Date/Time")
                {
                    ShowMandatory = true;
                }
                field("Recurrence Run Date Formula"; Rec."Recurrence Run Date Formula")
                {
                }
                field("Expiration Date/Time"; Rec."Expiration Date/Time")
                {
                    Visible = false;
                }
                field("Custom Filters"; Rec."Custom Filters")
                {
                }
                field("Start Date Filter Formula"; Rec."Start Date Filter Formula")
                {
                }
                field("End Date Filter Formula"; Rec."End Date Filter Formula")
                {
                }
                field("Date Filter Period Formula"; Rec."Date Filter Period Formula")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CustomFilters)
            {
                Caption = 'Custom Filters';
                Enabled = Rec.Code <> '';
                Image = EditFilter;
                Scope = Repeater;
                ToolTip = 'Edit the custom filters for the schedule, which are used when the schedule exports the PDF and Excel reports.';

                trigger OnAction()
                begin
                    Rec.EditCustomFilters();
                end;
            }
        }
        area(Navigation)
        {
            action(Recipients)
            {
                Caption = 'Recipients';
                Enabled = Rec.Code <> '';
                Image = Users;
                RunObject = page "Financial Report Recipients";
                RunPageLink =
                    "Financial Report Name" = field("Financial Report Name"),
                    "Financial Report Schedule Code" = field(Code);
                RunPageMode = Edit;
                Scope = Repeater;
                ToolTip = 'View or edit the recipients for the schedule.';
            }
            action(Logs)
            {
                Caption = 'Logs';
                Enabled = Rec.Code <> '';
                Image = Log;
                RunObject = page "Financial Report Export Logs";
                RunPageLink =
                    "Financial Report Name" = field("Financial Report Name"),
                    "Financial Report Schedule Code" = field(Code);
                RunPageMode = View;
                Scope = Repeater;
                ToolTip = 'View the export logs for the schedule.';
            }
        }
        area(Promoted)
        {
            actionref(EditFilters_Promoted; CustomFilters) { }
            actionref(Recipients_Promoted; Recipients) { }
            actionref(Logs_Promoted; Logs) { }
        }
    }
}