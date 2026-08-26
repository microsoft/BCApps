// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Inventory.Location;

pageextension 7420 "Excise Location Card Ext" extends "Location Card"
{
    layout
    {
        addlast(General)
        {
            field(Bonded; Rec.Bonded)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that this is a bonded location. Goods held in bond are not subject to excise duty until they are released from the bonded location.';
            }
        }
    }
}
