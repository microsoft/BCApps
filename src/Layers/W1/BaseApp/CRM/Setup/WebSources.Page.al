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
                    ToolTip = 'Specifies the code for the Web source.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the Web source.';
                }
                field(URL; Rec.URL)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the URL to use to search for information about the contact on the Internet.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies whether a comment has been assigned to this Web source.';
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

