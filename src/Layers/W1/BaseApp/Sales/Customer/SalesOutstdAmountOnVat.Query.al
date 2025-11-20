// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Document;

query 1302 "Sales Outstd. Amount On VAT"
{
    QueryType = Normal;

    elements
    {
        dataitem(DataItemName; "Sales Line")
        {
            column(Document_Type; "Document Type") { }
            column(Bill_to_Customer_No_; "Bill-to Customer No.") { }
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
