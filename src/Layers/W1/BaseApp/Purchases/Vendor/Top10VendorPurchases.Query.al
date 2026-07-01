// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Payables;

query 9088 "Top 10 Vendor Purchases"
{
    Caption = 'Top 10 Vendor Purchases';
    DataAccessIntent = ReadOnly;
    OrderBy = ascending(Sum_Purchases_LCY);
    TopNumberOfRows = 10;

    InherentEntitlements = X;
    InherentPermissions = X;

    elements
    {
        dataitem(Vendor_Ledger_Entry; "Vendor Ledger Entry")
        {
            DataItemTableFilter = "Purchase (LCY)" = filter(< 0);
            filter(Posting_Date; "Posting Date")
            {
            }
            column(Vendor_No; "Vendor No.")
            {
            }
            column(Sum_Purchases_LCY; "Purchase (LCY)")
            {
                Method = Sum;
            }
        }
    }
}
