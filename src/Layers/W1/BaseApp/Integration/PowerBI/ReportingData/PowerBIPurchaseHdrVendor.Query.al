// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

query 64 "Power BI Purchase Hdr. Vendor"
{
    Caption = 'Power BI Purchase Hdr. Vendor';

    elements
    {
        dataitem(Purchase_Header; "Purchase Header")
        {
            column(No; "No.")
            {
            }
            dataitem(Purchase_Line; "Purchase Line")
            {
                DataItemLink = "Document Type" = Purchase_Header."Document Type", "Document No." = Purchase_Header."No.";
                DataItemTableFilter = Type = const(Item);
                column(Item_No; "No.")
                {
                }
                column(Quantity; Quantity)
                {
                }
                dataitem(Item; Item)
                {
                    DataItemLink = "No." = Purchase_Line."No.";
                    column(Base_Unit_of_Measure; "Base Unit of Measure")
                    {
                    }
                    column(Description; Description)
                    {
                    }
                    column(Inventory; Inventory)
                    {
                    }
                    column(Qty_on_Purch_Order; "Qty. on Purch. Order")
                    {
                    }
                    column(Unit_Price; "Unit Price")
                    {
                    }
                    dataitem(Vendor; Vendor)
                    {
                        DataItemLink = "No." = Purchase_Header."Buy-from Vendor No.";
                        column(Vendor_No; "No.")
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

