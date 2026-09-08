// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Inventory.Item;

pageextension 11036 "E-Doc Item Charges DE" extends "Item Charges"
{
    layout
    {
        modify("E-Invoice Mapping")
        {
            Visible = true;
        }
        modify("E-Invoice Reason Text")
        {
            Visible = true;
        }
        modify("E-Invoice Reason Code")
        {
            Visible = true;
        }
        modify("E-Invoice Unit Code")
        {
            Visible = true;
        }
    }
}
