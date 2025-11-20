// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Comment;

page 5121 "Sales Cycle Stages"
{
    Caption = 'Sales Cycle Stages';
    DataCaptionFields = "Sales Cycle Code";
    PageType = List;
    SourceTable = "Sales Cycle Stage";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Stage; Rec.Stage)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the stage within the sales cycle.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the sales cycle stage.';
                }
                field("Completed %"; Rec."Completed %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the percentage of the sales cycle that has been completed when the opportunity reaches this stage.';
                }
                field("Chances of Success %"; Rec."Chances of Success %")
                {
                    ApplicationArea = RelationshipMgmt;
                    DecimalPlaces = 0 : 0;
                    ToolTip = 'Specifies the percentage of success that has been achieved when the opportunity reaches this stage.';
                }
                field("Activity Code"; Rec."Activity Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the activity linked to this sales cycle stage (if there is one).';
                }
                field("Quote Required"; Rec."Quote Required")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that a quote is required at this stage before the opportunity can move to the next stage in the sales cycle.';
                }
                field("Allow Skip"; Rec."Allow Skip")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that it is possible to skip this stage and move the opportunity to the next stage.';
                }
                field("Date Formula"; Rec."Date Formula")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies how dates for planned activities are calculated when you run the Opportunity - Details report.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that comments exist for this sales cycle stage.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Sales Cycle Stage")
            {
                Caption = '&Sales Cycle Stage';
                Image = Stages;
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Sales Cycle Stage Statistics";
                    RunPageLink = "Sales Cycle Code" = field("Sales Cycle Code"),
                                  Stage = field(Stage);
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const("Sales Cycle Stage"),
                                  "No." = field("Sales Cycle Code"),
                                  "Sub No." = field(Stage);
                    ToolTip = 'View or add comments for the record.';
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
            }
        }
    }
}

