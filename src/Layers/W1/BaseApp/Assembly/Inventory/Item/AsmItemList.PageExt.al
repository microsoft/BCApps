// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Reports;

pageextension 905 "Asm. Item List" extends "Item List"
{
    actions
    {
        addbefore("Inventory - Sales Back Orders")
        {
            action("Assemble to Order - Sales")
            {
                ApplicationArea = Assembly;
                Caption = 'Assemble to Order - Sales';
                Image = "Report";
                RunObject = Report "Assemble to Order - Sales";
            }
        }
    }
}