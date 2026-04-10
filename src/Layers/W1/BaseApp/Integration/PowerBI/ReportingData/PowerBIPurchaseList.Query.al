// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Purchases.Document;

query 56 "Power BI Purchase List"
{
    Caption = 'Power BI Purchase List';

    elements
    {
        dataitem(Purchase_Header; "Purchase Header")
        {
            column(Document_No; "No.")
            {
            }
            column(Order_Date; "Order Date")
            {
            }
            column(Expected_Receipt_Date; "Expected Receipt Date")
            {
            }
            column(Due_Date; "Due Date")
            {
            }
            column(Pmt_Discount_Date; "Pmt. Discount Date")
            {
            }
            dataitem(Purchase_Line; "Purchase Line")
            {
                DataItemLink = "Document No." = Purchase_Header."No.";
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

