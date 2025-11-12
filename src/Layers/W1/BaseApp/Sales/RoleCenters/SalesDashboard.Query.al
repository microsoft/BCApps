// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;

query 101 "Sales Dashboard"
{
    Caption = 'Sales Dashboard';

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {
            DataItemTableFilter = "Entry Type" = filter(Sale);
            column(Entry_No; "Entry No.")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Entry_Type; "Entry Type")
            {
            }
            column(Quantity; Quantity)
            {
            }
            column(Sales_Amount_Actual; "Sales Amount (Actual)")
            {
            }
            column(Sales_Amount_Expected; "Sales Amount (Expected)")
            {
            }
            column(Cost_Amount_Actual; "Cost Amount (Actual)")
            {
            }
            column(Cost_Amount_Expected; "Cost Amount (Expected)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Country_Region; "Country/Region")
            {
                DataItemLink = Code = Item_Ledger_Entry."Country/Region Code";
                column(CountryRegionName; Name)
                {
                }
                dataitem(Customer; Customer)
                {
                    DataItemLink = "No." = Item_Ledger_Entry."Source No.";
                    column(CustomerName; Name)
                    {
                    }
                    column(Customer_Posting_Group; "Customer Posting Group")
                    {
                    }
                    column(Customer_Disc_Group; "Customer Disc. Group")
                    {
                    }
                    column(City; City)
                    {
                    }
                    dataitem(Item; Item)
                    {
                        DataItemLink = "No." = Item_Ledger_Entry."Item No.";
                        column(Description; Description)
                        {
                        }
                        dataitem(Salesperson_Purchaser; "Salesperson/Purchaser")
                        {
                            DataItemLink = Code = Customer."Salesperson Code";
                            column(SalesPersonName; Name)
                            {
                            }
                        }
                    }
                }
            }
        }
    }
}

