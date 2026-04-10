// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

page 5188 "Inter. Log Entry Comment List"
{
    Caption = 'Inter. Log Entry Comment List';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Inter. Log Entry Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
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

