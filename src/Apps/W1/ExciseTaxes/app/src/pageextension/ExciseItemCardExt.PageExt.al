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
        addafter(Sustainability)
        {
            group("Excise Tax")
            {
                Caption = 'Excise Tax';
                field("Excise Tax Type"; Rec."Excise Tax Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which excise tax type applies to this item.';
                }
                field("Qty for Excise Tax"; Rec."Qty for Excise Tax")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount per unit based on tax basis.';
                }
                field("Excise Tax UOM"; Rec."Excise Tax UOM")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure for tax basis.';
                }
            }
        }
    }
}