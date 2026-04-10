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
                }
                field("Sub No."; Rec."Sub No.")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = RelationshipMgmt;
                }
            }
        }
    }

    actions
    {
    }
}

