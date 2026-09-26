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
            field("Qty. on Transfer Order (Base)"; Rec."Subc. Qty.on TransOrder (Base)")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Qty. on Transfer Order (Base)';
                ToolTip = 'Specifies the item amount that is on the transfer order.';
            }
            field("Qty. in Transit (Base)"; Rec."Subc. Qty. in Transit (Base)")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Qty. in Transit (Base)';
                ToolTip = 'Specifies the items that are in transit.';
                Visible = false;
            }
            field("Qty. transf. to Subcontractor"; Rec."Subc. Qty. transf. to Subcontr")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Qty. transf. to Subcontractor';
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
