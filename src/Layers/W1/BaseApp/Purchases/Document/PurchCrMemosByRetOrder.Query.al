// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.History;

query 204 "Purch. Cr. Memos By Ret. Order"
{
    Caption = 'Purch. Cr. Memos By Ret. Order';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(PurchCrMemoLine; "Purch. Cr. Memo Line")
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
