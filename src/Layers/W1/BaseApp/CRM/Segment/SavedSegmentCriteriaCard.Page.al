// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

page 5140 "Saved Segment Criteria Card"
{
    Caption = 'Saved Segment Criteria Card';
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Saved Segment Criteria";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
            part(Control11; "Saved Segment Criteria Subform")
            {
                ApplicationArea = RelationshipMgmt;
                SubPageLink = "Segment Criteria Code" = field(Code);
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
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Close();
    end;
}

