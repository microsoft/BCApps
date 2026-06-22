// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

pageextension 99001512 "Subc. Prod Order Comp" extends "Prod. Order Components"
{
    layout
    {
        addafter("Remaining Quantity")
        {
            field("Subc. Qty.on TransOrder (Base)"; Rec."Subc. Qty.on TransOrder (Base)")
            {
                ApplicationArea = Subcontracting;
            }
            field("Subc. Qty. in Transit (Base)"; Rec."Subc. Qty. in Transit (Base)")
            {
                ApplicationArea = Subcontracting;
                Visible = false;
            }
            field("Subc. Qty. transf. to Subcontractor"; Rec."Subc. Qty. transf. to Subcontr")
            {
                ApplicationArea = Subcontracting;
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