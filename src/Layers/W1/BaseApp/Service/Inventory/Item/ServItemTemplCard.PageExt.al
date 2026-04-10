// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

pageextension 6464 "Serv. Item Templ. Card" extends "Item Templ. Card"
{
    layout
    {
        addafter("Sales Blocked")
        {
            field("Service Blocked"; Rec."Service Blocked")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies that the item cannot be entered on service items, service contracts and service documents, except credit memos.';
            }
        }
        addafter("Manufacturer Code")
        {
            field("Service Item Group"; Rec."Service Item Group")
            {
                ApplicationArea = Service;
                Importance = Additional;
                ToolTip = 'Specifies the code of the service item group that the item belongs to.';
            }
        }
    }
}
