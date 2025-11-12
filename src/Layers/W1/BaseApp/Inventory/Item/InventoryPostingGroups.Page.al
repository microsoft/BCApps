// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using System.Text;

page 112 "Inventory Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Posting Groups';
    PageType = List;
    SourceTable = "Inventory Posting Group";
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier for the inventory posting group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the inventory posting group.';
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
        area(processing)
        {
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "Inventory Posting Setup";
                RunPageLink = "Invt. Posting Group Code" = field(Code);
                ToolTip = 'Specify the locations for the inventory posting group that you can link to general ledger accounts. Posting groups create links between application areas and the General Ledger application area.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Setup_Promoted"; "&Setup")
                {
                }
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        InvtPostingGr: Record "Inventory Posting Group";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(InvtPostingGr);
        exit(SelectionFilterManagement.GetSelectionFilterForInventoryPostingGroup(InvtPostingGr));
    end;
}

