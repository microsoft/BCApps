// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

query 4406 "EXR Trial Balance Budget"
{
    Access = Internal;
    DataAccessIntent = ReadOnly;
    QueryType = Normal;

    elements
    {
        dataitem(GLAccount; "G/L Account")
        {
            column(AccountNumber; "No.")
            {
            }
            dataitem(GLBudgetEntry; "G/L Budget Entry")
            {
                DataItemLink = "G/L Account No." = GLAccount."No.";
                SqlJoinType = InnerJoin;
                column(Amount; Amount)
                {
                    Method = sum;
                }
                filter(BudgetDate; Date)
                {
                }
                column(DimensionValue1Code; "Global Dimension 1 Code")
                {
                }
                column(DimensionValue2Code; "Global Dimension 2 Code")
                {
                }
                filter(BudgetName; "Budget Name")
                {
                }
            }
        }
    }
}
