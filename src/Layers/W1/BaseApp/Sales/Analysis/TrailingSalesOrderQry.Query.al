// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Sales.Document;

query 760 "Trailing Sales Order Qry"
{
    Caption = 'Trailing Sales Order Qry';

    elements
    {
        dataitem(Sales_Header; "Sales Header")
        {
            DataItemTableFilter = "Document Type" = const(Order);
            filter(ShipmentDate; "Shipment Date")
            {
            }
            filter(Status; Status)
            {
            }
            filter(DocumentDate; "Document Date")
            {
            }
            column(CurrencyCode; "Currency Code")
            {
            }
            dataitem(Sales_Line; "Sales Line")
            {
                DataItemLink = "Document Type" = Sales_Header."Document Type", "Document No." = Sales_Header."No.";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = Amount = filter(<> 0);
                column(Amount; Amount)
                {
                    Method = Sum;
                }
            }
        }
    }
}

