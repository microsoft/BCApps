// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

page 5187 "Inter. Log Entry Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Inter. Log Entry Comment Sheet';
    DataCaptionFields = "Entry No.";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Inter. Log Entry Comment Line";

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

