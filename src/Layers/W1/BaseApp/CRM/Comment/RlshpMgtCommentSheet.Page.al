// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Comment;

page 5072 "Rlshp. Mgt. Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Rlshp. Mgt. Comment Sheet';
    DataCaptionFields = "No.";
    DelayedInsert = true;
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
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;
}

