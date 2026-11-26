// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Inventory.Ledger;

pageextension 31304 "Item Ledger Entries CZ" extends "Item Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("Statistic Indication CZ"; Rec."Statistic Indication CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Statistic indication for Intrastat reporting purposes.';
                Visible = false;
            }
            field("Country/Reg. of Orig. Code CZ"; Rec."Country/Reg. of Orig. Code CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
                Visible = false;
            }
            field("Physical Transfer CZ"; Rec."Physical Transfer CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if there is physical transfer of the item.';
                Visible = false;
            }
        }
    }
}
