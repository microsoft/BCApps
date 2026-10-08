// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.InventoryDocument;

pageextension 20577 "Subc. Pstd. Invt. Putaway" extends "Posted Invt. Put-away Subform"
{
    layout
    {
        addlast(Control1)
        {
            field("Subc. Purchase Line Type"; Rec."Subc. Purchase Line Type")
            {
                ApplicationArea = Subcontracting;
                Visible = false;
            }
            field("Subc. Transfer WIP Item"; Rec."Transfer WIP Item")
            {
                ApplicationArea = Subcontracting;
                Visible = false;
            }
        }
    }
}