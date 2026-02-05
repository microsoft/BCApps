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
            field("Qty. on Transfer Order (Base)"; Rec."Qty. on Trans Order (Base)")
            {
                ApplicationArea = Location;
            }
            field("Qty. in Transit (Base)"; Rec."Qty. in Transit (Base)")
            {
                ApplicationArea = Location;
                Visible = false;
            }
            field("Qty. transf. to Subcontractor"; Rec."Qty. transf. to Subcontr")
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