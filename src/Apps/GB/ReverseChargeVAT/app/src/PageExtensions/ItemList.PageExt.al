// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Inventory.Item;

pageextension 10553 "Item List" extends "Item List"
{
    layout
    {
        addafter("Item Tracking Code")
        {
            field("Reverse Charge Applies GB"; Rec."Reverse Charge Applies GB")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if this item is subject to reverse charge.';
            }
        }
    }


}