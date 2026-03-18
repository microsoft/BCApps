// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

pageextension 99000753 "Mfg. Item Lookup" extends "Item Lookup"
{
    layout
    {
        addafter("Stockkeeping Unit Exists")
        {
            field("Routing No."; Rec."Routing No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the production route that contains the operations needed to manufacture this item.';
            }
        }
    }
}