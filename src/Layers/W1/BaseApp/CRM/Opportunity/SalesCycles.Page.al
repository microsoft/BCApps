// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Comment;

page 5119 "Sales Cycles"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Sales Cycles';
    PageType = List;
    SourceTable = "Sales Cycle";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the sales cycle.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the sales cycle.';
                }
                field("Probability Calculation"; Rec."Probability Calculation")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the method to use to calculate the probability of opportunities completing the sales cycle. There are four options:';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that you have assigned comments to the sales cycle.';
                }
            }
        }
        area(factboxes)
        {
            part(Control5; "Sales Cycle Statistics FactBox")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Statistics';
                SubPageLink = Code = field(Code);
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Sales &Cycle")
            {
                Caption = 'Sales &Cycle';
                Image = Stages;
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Sales Cycle Statistics";
                    RunPageLink = Code = field(Code);
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const("Sales Cycle"),
                                  "No." = field(Code),
                                  "Sub No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action("S&tages")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'S&tages';
                    Image = Stages;
                    RunObject = Page "Sales Cycle Stages";
                    RunPageLink = "Sales Cycle Code" = field(Code);
                    ToolTip = 'View a list of the different stages within the sales cycle.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("S&tages_Promoted"; "S&tages")
                {
                }
            }
        }
    }
}

