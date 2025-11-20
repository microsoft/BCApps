// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

page 753 "Standard Item Journals"
{
    Caption = 'Standard Item Journals';
    CardPageID = "Standard Item Journal";
    DataCaptionFields = "Journal Template Name";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Standard Item Journal";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
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
        area(navigation)
        {
            group("&Standard")
            {
                Caption = '&Standard';
                Image = Journal;
                action("&Show Journal")
                {
                    ApplicationArea = Suite;
                    Caption = '&Show Journal';
                    Image = Journal;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open a journal based on the journal batch that you selected.';

                    trigger OnAction()
                    var
                        StdItemJnl: Record "Standard Item Journal";
                    begin
                        StdItemJnl.SetRange("Journal Template Name", Rec."Journal Template Name");
                        StdItemJnl.SetRange(Code, Rec.Code);

                        PAGE.Run(PAGE::"Standard Item Journal", StdItemJnl);
                    end;
                }
            }
        }
    }
}

