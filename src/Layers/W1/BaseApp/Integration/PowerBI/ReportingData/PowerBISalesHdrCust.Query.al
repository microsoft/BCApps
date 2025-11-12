// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Sales.Document;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

query 60 "Power BI Sales Hdr. Cust."
{
    Caption = 'Power BI Sales Hdr. Cust.';

    elements
    {
        dataitem(Sales_Header; "Sales Header")
        {
            column(No; "No.")
            {
            }
            dataitem(Sales_Line; "Sales Line")
            {
                DataItemLink = "Document Type" = Sales_Header."Document Type", "Document No." = Sales_Header."No.";
                DataItemTableFilter = Type = const(Item);
                column(Item_No; "No.")
                {
                }
                column(Quantity; Quantity)
                {
                }
                column(Qty_Invoiced_Base; "Qty. Invoiced (Base)")
                {
                }
                column(Qty_Shipped_Base; "Qty. Shipped (Base)")
                {
                }
                dataitem(Item; Item)
                {
                    DataItemLink = "No." = Sales_Line."No.";
                    column(Base_Unit_of_Measure; "Base Unit of Measure")
                    {
                    }
                    column(Description; Description)
                    {
                    }
                    column(Inventory; Inventory)
                    {
                    }
                    column(Unit_Price; "Unit Price")
                    {
                    }
                    dataitem(Customer; Customer)
                    {
                        DataItemLink = "No." = Sales_Line."Sell-to Customer No.";
                        column(Customer_No; "No.")
                        {
                        }
                        column(Name; Name)
                        {
                        }
                        column(Balance; Balance)
                        {
                        }
                        column(Country_Region_Code; "Country/Region Code")
                        {
                        }
                    }
                }
            }
        }
    }
}

