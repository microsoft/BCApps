// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

query 4405 "EXR Trial Balance"
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
            filter(AccountNo; "No.")
            {
            }
            dataitem(GLEntry; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = GLAccount."No.";
                SqlJoinType = InnerJoin;
                column(Amount; Amount)
                {
                    Method = sum;
                }
                column(ACYAmount; "Additional-Currency Amount")
                {
                    Method = sum;
                }
                column(DimensionValue1Code; "Global Dimension 1 Code")
                {
                }
                column(DimensionValue2Code; "Global Dimension 2 Code")
                {
                }
                filter(PostingDate; "Posting Date")
                {
                }
            }
        }
    }
}
