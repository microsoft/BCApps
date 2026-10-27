// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Sales.Document;

pageextension 31328 "Sales Return Order Subform CZ" extends "Sales Return Order Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("Statistic Indication CZ"; Rec."Statistic Indication CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the statistic indication code.';
                Visible = false;
            }
            field("Country/Reg. of Orig. Code CZ"; Rec."Country/Reg. of Orig. Code CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
                Visible = false;
            }
        }
    }
}