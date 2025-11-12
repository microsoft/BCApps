// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

pageextension 99000796 "Mfg. Item Variants" extends "Item Variants"
{
    layout
    {
        addafter("Purchasing Blocked")
        {
            field("Production Blocked"; Rec."Production Blocked")
            {
                ApplicationArea = Manufacturing;
            }
        }
    }
}