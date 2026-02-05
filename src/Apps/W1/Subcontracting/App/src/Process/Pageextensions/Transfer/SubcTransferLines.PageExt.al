// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001530 "Subc. Transfer Lines" extends "Transfer Lines"
{
    layout
    {
        addlast(Control1)
        {
            field("Return Order"; Rec."Return Order")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                Visible = false;
            }
        }
    }
}