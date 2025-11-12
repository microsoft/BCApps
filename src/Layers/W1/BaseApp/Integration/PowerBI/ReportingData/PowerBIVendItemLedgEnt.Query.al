// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Ledger;

query 65 "Power BI Vend. Item Ledg. Ent."
{
    Caption = 'Vendor Item Ledger Entries';

    elements
    {
        dataitem(Vendor; Vendor)
        {
            column(No; "No.")
            {
            }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Source No." = Vendor."No.";
                DataItemTableFilter = "Source Type" = const(Vendor);
                column(Item_No; "Item No.")
                {
                }
                column(Quantity; Quantity)
                {
                }
            }
        }
    }
}

