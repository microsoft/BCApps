// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;

pageextension 99001520 "Subc. Location Card" extends "Location Card"
{
    layout
    {
        addlast(General)
        {
            field("Direct Transfer Posting"; Rec."Direct Transfer Posting")
            {
                ApplicationArea = Location;
                ToolTip = 'Specifies if Direct Transfer should be posted separately as Shipment and Receipt or as single Direct Transfer document.';
            }
        }
    }
}