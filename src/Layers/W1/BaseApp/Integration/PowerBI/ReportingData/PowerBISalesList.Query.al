// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Sales.Document;

query 55 "Power BI Sales List"
{
    Caption = 'Power BI Sales List';

    elements
    {
        dataitem(Sales_Header; "Sales Header")
        {
            column(Document_No; "No.")
            {
            }
            column(Requested_Delivery_Date; "Requested Delivery Date")
            {
            }
            column(Shipment_Date; "Shipment Date")
            {
            }
            column(Due_Date; "Due Date")
            {
            }
            dataitem(Sales_Line; "Sales Line")
            {
                DataItemLink = "Document No." = Sales_Header."No.";
                column(Quantity; Quantity)
                {
                }
                column(Amount; Amount)
                {
                }
                column(Item_No; "No.")
                {
                }
                column(Description; Description)
                {
                }
            }
        }
    }
}

