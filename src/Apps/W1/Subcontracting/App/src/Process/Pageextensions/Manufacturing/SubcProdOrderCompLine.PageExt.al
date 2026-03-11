// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

pageextension 99001513 "Subc. ProdOrderCompLine" extends "Prod. Order Comp. Line List"
{
    layout
    {
        addlast(Control1)
        {
            field("Subcontracting Type"; Rec."Subcontracting Type")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the Type of Subcontracting that is assigned to the Production Component.';
            }
            field("Routing Link Code"; Rec."Routing Link Code")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the routing link code when you calculate the production order.';
            }
        }
    }
}