// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.History;

query 205 "Sales Cr. Memos By Ret. Order"
{
    Caption = 'Sales Cr. Memos By Ret. Order';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(SalesCrMemoLine; "Sales Cr.Memo Line")
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
