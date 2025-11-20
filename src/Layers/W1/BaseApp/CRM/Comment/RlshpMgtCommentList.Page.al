// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Comment;

page 5118 "Rlshp. Mgt. Comment List"
{
    Caption = 'Rlshp. Mgt. Comment List';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Rlshp. Mgt. Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sub No."; Rec."Sub No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the stage within the sales cycle.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the comment itself.';
                }
            }
        }
    }

    actions
    {
    }
}

