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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Purch. PD Charge FCY (Item)"; Rec."Purch. PD Charge FCY (Item)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase prepayment charge, in functional currency, for the item associated with the posting group.';
                }
                field("Purch. PD Charge Conv. (Item)"; Rec."Purch. PD Charge Conv. (Item)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase prepayment charge for the item associated with the posting group.';
                }
                field("Sales PD Charge FCY (Item)"; Rec."Sales PD Charge FCY (Item)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales prepayment charge, in functional currency, for the item associated with the posting group.';
                }
                field("Sales PD Charge Conv. (Item)"; Rec."Sales PD Charge Conv. (Item)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales prepayment charge for the item associated with the posting group.';
                }
                field("Sales Corr. Doc. Charge (Item)"; Rec."Sales Corr. Doc. Charge (Item)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item charge code that you want to use in in value entries to correct the original price of items in the corrective documents.';
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

