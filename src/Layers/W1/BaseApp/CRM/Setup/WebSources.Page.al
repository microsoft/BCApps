// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.Comment;

page 5069 "Web Sources"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Web Sources';
    PageType = List;
    SourceTable = "Web Source";
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(URL; Rec.URL)
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
            group("&Web Sources")
            {
                Caption = '&Web Sources';
                Image = ViewComments;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const("Web Source"),
                                  "No." = field(Code),
                                  "Sub No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }
}

