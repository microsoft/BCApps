// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Inventory.Item;

pageextension 7415 "Excise Item Card Ext" extends "Item Card"
{
    layout
    {
#if not CLEAN29
        addafter(Sustainability)
        {
            group("Excise Tax")
            {
                Caption = 'Excise Tax';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the Item Excise Tax table to support multiple excise taxes per item.';
                ObsoleteTag = '29.0';
                field("Excise Tax Type"; Rec."Excise Tax Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which excise tax type applies to this item.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the Item Excise Tax table to support multiple excise taxes per item.';
                    ObsoleteTag = '29.0';
                }
                field("Quantity for Excise Tax"; Rec."Quantity for Excise Tax")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount per unit based on tax basis.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the Item Excise Tax table to support multiple excise taxes per item.';
                    ObsoleteTag = '29.0';
                }
                field("Excise Unit of Measure Code"; Rec."Excise Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure for tax basis.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the Item Excise Tax table to support multiple excise taxes per item.';
                    ObsoleteTag = '29.0';
                }
            }
        }
#endif
    }
    actions
    {
        addlast(Navigation)
        {
            action("Excise Taxes")
            {
                ApplicationArea = All;
                Caption = 'Excise Taxes';
                ToolTip = 'View or set up the excise taxes that apply to this item.';
                Image = Setup;
                RunObject = Page "Item Excise Taxes";
                RunPageLink = "Item No." = field("No.");
            }
        }
        addlast(Category_Category4)
        {
            actionref("Excise Taxes_Promoted"; "Excise Taxes")
            {
            }
        }
    }
}