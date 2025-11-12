// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

query 9150 "My Customers"
{
    Caption = 'My Customers';

    elements
    {
        dataitem(My_Customer; "My Customer")
        {
            filter(User_ID; "User ID")
            {
            }
            column(Customer_No; "Customer No.")
            {
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = My_Customer."Customer No.";
                filter(Date_Filter; "Date Filter")
                {
                }
                column(Sum_Sales_LCY; "Sales (LCY)")
                {
                    Method = Sum;
                }
                column(Sum_Profit_LCY; "Profit (LCY)")
                {
                    Method = Sum;
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
        SetRange(User_ID, UserId);
    end;
}

