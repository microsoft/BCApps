// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;

query 104 "Sales Orders by Sales Person"
{
    Caption = 'Sales Orders by Sales Person';

    elements
    {
        dataitem(Sales_Line; "Sales Line")
        {
            column(ItemNo; "No.")
            {
            }
            column(ItemDescription; Description)
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Amount; Amount)
            {
            }
            column(Line_No; "Line No.")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Currency; Currency)
            {
                DataItemLink = Code = Sales_Line."Currency Code";
                column(CurrenyDescription; Description)
                {
                }
                dataitem(Sales_Header; "Sales Header")
                {
                    DataItemLink = "No." = Sales_Line."Document No.";
                    column(Currency_Code; "Currency Code")
                    {
                    }
                    dataitem(Salesperson_Purchaser; "Salesperson/Purchaser")
                    {
                        DataItemLink = Code = Sales_Header."Salesperson Code";
                        column(SalesPersonCode; "Code")
                        {
                        }
                        column(SalesPersonName; Name)
                        {
                        }
                    }
                }
            }
        }
    }
}

