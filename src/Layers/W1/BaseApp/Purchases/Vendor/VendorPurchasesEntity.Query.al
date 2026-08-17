// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Payables;

query 5481 "Vendor Purchases Entity"
{
    Caption = 'vendorPurchases', Locked = true;
    EntityName = 'vendorPurchase';
    EntitySetName = 'vendorPurchases';
    QueryType = API;

    elements
    {
        dataitem(Vendor; Vendor)
        {
            column(vendorId; SystemId)
            {
                Caption = 'Id', Locked = true;
            }
            column(vendorNumber; "No.")
            {
                Caption = 'No', Locked = true;
            }
            column(name; Name)
            {
                Caption = 'Name', Locked = true;
            }
            dataitem(Vendor_Ledger_Entry; "Vendor Ledger Entry")
            {
                DataItemLink = "Vendor No." = Vendor."No.";
                SqlJoinType = LeftOuterJoin;
                column(totalPurchaseAmount; "Purchase (LCY)")
                {
                    Caption = 'TotalPurchaseAmount', Locked = true;
                    Method = Sum;
                    ReverseSign = true;
                }
                filter(dateFilter; "Posting Date")
                {
                    Caption = 'DateFilter', Locked = true;
                }
            }
        }
    }
}

