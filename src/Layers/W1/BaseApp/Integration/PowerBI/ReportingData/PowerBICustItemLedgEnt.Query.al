// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;

query 61 "Power BI Cust. Item Ledg. Ent."
{
    Caption = 'Power BI Cust. Item Ledg. Ent.';

    elements
    {
        dataitem(Customer; Customer)
        {
            column(No; "No.")
            {
            }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Source No." = Customer."No.";
                DataItemTableFilter = "Source Type" = const(Customer);
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

