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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Completed %"; Rec."Completed %")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Chances of Success %"; Rec."Chances of Success %")
                {
                    ApplicationArea = RelationshipMgmt;
                    DecimalPlaces = 0 : 0;
                }
                field("Activity Code"; Rec."Activity Code")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Quote Required"; Rec."Quote Required")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Allow Skip"; Rec."Allow Skip")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Date Formula"; Rec."Date Formula")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
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

