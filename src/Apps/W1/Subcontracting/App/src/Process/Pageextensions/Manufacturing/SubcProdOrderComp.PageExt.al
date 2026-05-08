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
            field("Qty. on Transfer Order (Base)"; Rec."Subc. Qty.on TransOrder (Base)")
            {
                ApplicationArea = Location;
            }
            field("Qty. in Transit (Base)"; Rec."Subc. Qty. in Transit (Base)")
            {
                ApplicationArea = Location;
                Visible = false;
            }
            field("Subc. Qty. transf. to Subcontractor"; Rec."Subc. Qty. transf. to Subcontr")
            {
                ApplicationArea = Manufacturing;
            }
        }
        addlast(Control1)
        {
            field("Subcontracting Type"; Rec."Subcontracting Type")
            {
                ApplicationArea = Manufacturing;
            }
        }
    }
}