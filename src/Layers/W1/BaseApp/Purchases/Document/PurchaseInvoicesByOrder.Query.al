// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.History;

query 200 "Purchase Invoices By Order"
{
    Caption = 'Purchase Invoices By Order';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(PurchInvLine; "Purch. Inv. Line")
        {
            column(Document_No_; "Document No.")
            {
            }
            column(LinesCount)
            {
                Method = Count;
            }
            filter(Order_No_; "Order No.")
            {
            }
            filter(Quantity; Quantity)
            {
            }
        }
    }
}
