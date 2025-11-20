// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

page 754 "Standard Item Journal"
{
    Caption = 'Standard Item Journal';
    PageType = ListPlus;
    SourceTable = "Standard Item Journal";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the record in the line of the journal.';
                }
            }
            part(StdItemJnlLines; "Standard Item Journal Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Standard Journal Code" = field(Code);
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if xRec.Code = '' then
            Rec.SetRange(Code, Rec.Code);
    end;
}

