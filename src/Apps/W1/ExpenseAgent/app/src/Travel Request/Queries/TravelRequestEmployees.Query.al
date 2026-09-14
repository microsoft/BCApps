// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

query 7111 "Travel Request Employees"
{
    Access = Internal;
    Permissions = tabledata "Spend Request" = r,
                  tabledata Traveler = r,
                  tabledata "Expense User" = r;

    elements
    {
        dataitem(spendRequest; "Spend Request")
        {
            DataItemTableFilter = "Document Type" = const("Travel Request");
            filter(travelRequestSystemId; SystemId) { }

            dataitem(traveler; Traveler)
            {
                DataItemLink = "Spend Request No." = spendRequest."No.";
                SqlJoinType = InnerJoin;

                dataitem(expenseUser; "Expense User")
                {
                    DataItemLink = "No." = traveler."Expense User No.";
                    SqlJoinType = InnerJoin;

                    column(employeeNo; "Employee No.") { }
                }
            }
        }
    }
}
