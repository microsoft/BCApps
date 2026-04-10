// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Sales.Customer;

query 1319 "Sales by Cust. Grp. Chart Mgt."
{
    Access = Internal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Customer_Posting_Group; "Customer Posting Group")
        {
            column(Code; Code)
            {
            }

            dataitem(Customer; Customer)
            {
                DataItemLink = "Customer Posting Group" = Customer_Posting_Group.Code;

                filter(Date_Filter; "Date Filter")
                {

                }

                column(Sales__LCY_; "Sales (LCY)")
                {
                    Method = Sum;
                }
            }
        }
    }
}
