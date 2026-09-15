// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Document;

query 1313 "Purch. Outstd. Amount On VAT"
{
    QueryType = Normal;

    elements
    {
        dataitem(DataItemName; "Purchase Line")
        {
            column(Document_Type; "Document Type") { }
            column(Buy_from_Vendor_No_; "Buy-from Vendor No.") { }
            column(VAT__; "VAT %") { }
            column(Sum_Outstanding_Amount__LCY_; "Outstanding Amount (LCY)")
            {
                Method = Sum;
            }
        }
    }

    trigger OnBeforeOpen()
    begin

    end;
}
