// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

pageextension 20513 "Subc. ProdOrderCompLine" extends "Prod. Order Comp. Line List"
{
    layout
    {
        addafter("Remaining Quantity")
        {
            field("Subc. Qty.on TransOrder (Base)"; Rec."Subc. Qty.on TransOrder (Base)")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the item amount that is on the transfer order.';
            }
            field("Subc. Qty. in Transit (Base)"; Rec."Subc. Qty. in Transit (Base)")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the items that are in transit.';
                Visible = false;
            }
            field("Subc. Qty. transf. to Subcontractor"; Rec."Subc. Qty. transf. to Subcontr")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the item amount transferred to the subcontractor.';
            }
        }
        addlast(Control1)
        {
            field("Component Supply Method"; Rec."Component Supply Method")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies how components are supplied to the subcontractor for the production component.';
            }
        }
    }
}
