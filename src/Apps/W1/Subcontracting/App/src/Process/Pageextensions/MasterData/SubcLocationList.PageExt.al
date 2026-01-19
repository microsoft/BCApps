// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;

pageextension 99001521 "Subc. Location List" extends "Location List"
{
    layout
    {
        addlast(Control1)
        {
            field("Direct Transfer Posting"; Rec."Direct Transfer Posting")
            {
                ApplicationArea = Location;
            }
        }
    }
}