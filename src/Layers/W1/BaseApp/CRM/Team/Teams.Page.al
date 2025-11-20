// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Team;

using Microsoft.CRM.Reports;
using Microsoft.CRM.Task;

page 5105 Teams
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Teams';
    PageType = List;
    SourceTable = Team;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the team.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the team.';
                }
                field("Next Task Date"; Rec."Next Task Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the next task involving the team.';

                    trigger OnDrillDown()
                    var
                        Task: Record "To-do";
                    begin
                        Task.SetCurrentKey("Team Code", Date, Closed);
                        Task.SetRange("Team Code", Rec.Code);
                        Task.SetRange(Closed, false);
                        Task.SetRange("System To-do Type", Task."System To-do Type"::Team);
                        if Task.FindFirst() then
                            PAGE.Run(0, Task);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Team")
            {
                Caption = '&Team';
                Image = SalesPurchaseTeam;
                action(Tasks)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tasks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Team Code" = field(Code),
                                  "System To-do Type" = filter(Team);
                    RunPageView = sorting("Team Code");
                    ToolTip = 'View the list of marketing tasks that exist.';
                }
                action(Salespeople)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Salespeople';
                    Image = ExportSalesPerson;
                    RunObject = Page "Team Salespeople";
                    RunPageLink = "Team Code" = field(Code);
                    ToolTip = 'View a list of salespeople within the team.';
                }
            }
        }
        area(reporting)
        {
            action("Team - Tasks")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Team - Tasks';
                Image = "Report";
                RunObject = Report "Team - Tasks";
                ToolTip = 'View the list of marketing tasks that exist for the team.';
            }
            action("Salesperson - Tasks")
            {
                ApplicationArea = Suite;
                Caption = 'Salesperson - Tasks';
                Image = "Report";
                RunObject = Report "Salesperson - Tasks";
                ToolTip = 'View the list of marketing tasks that exist for the salesperson.';
            }
            action("Salesperson - Opportunities")
            {
                ApplicationArea = Suite;
                Caption = 'Salesperson - Opportunities';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Salesperson - Opportunities";
                ToolTip = 'View information about the opportunities handled by one or several salespeople.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Salespeople_Promoted; Salespeople)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Team - Tasks_Promoted"; "Team - Tasks")
                {
                }
                actionref("Salesperson - Tasks_Promoted"; "Salesperson - Tasks")
                {
                }
            }
        }
    }
}

