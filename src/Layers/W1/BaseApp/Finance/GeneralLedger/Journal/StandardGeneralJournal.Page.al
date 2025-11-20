// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

page 751 "Standard General Journal"
{
    Caption = 'Standard General Journal';
    PageType = ListPlus;
    SourceTable = "Standard General Journal";

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
                    ToolTip = 'Specifies a code to identify the standard general journal that you are about to save.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a text that indicates the purpose of the standard general journal.';
                }
            }
            part(StdGenJnlLines; "Standard Gen. Journal Subform")
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

