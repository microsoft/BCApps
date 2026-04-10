// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

query 202 "Service Invoices By Order"
{
    Caption = 'Service Invoices By Order';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ServiceInvoiceLine; "Service Invoice Line")
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
