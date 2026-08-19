// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Aggregates Detailed Cust. Ledger Entry amounts in a single SQL round-trip by JOINing to Customer
/// for entries with a blank "Posting Group" (legacy/upgraded data). Used by report 33 "Reconcile
/// Cust. and Vend. Accs" to attribute historical detail entries to the customer's current master
/// "Customer Posting Group" without iterating customers in AL.
/// </summary>
query 33 "Recon. Cust. Posting Gr. Sum"
{
    Caption = 'Reconcile Customer Posting Group Sum';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    Access = Internal;

    elements
    {
        dataitem(DtldCustLedgEntry; "Detailed Cust. Ledg. Entry")
        {
            column(EntryType; "Entry Type")
            {
            }
            filter(PostingDate; "Posting Date")
            {
            }
            filter(PostingGroup; "Posting Group")
            {
            }
            column(SumAmountLCY; "Amount (LCY)")
            {
                Method = Sum;
            }
            column(SumCreditAmountLCY; "Credit Amount (LCY)")
            {
                Method = Sum;
            }
            column(SumDebitAmountLCY; "Debit Amount (LCY)")
            {
                Method = Sum;
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = DtldCustLedgEntry."Customer No.";
                SqlJoinType = InnerJoin;

                filter(CustomerPostingGroup; "Customer Posting Group")
                {
                }
            }
        }
    }
}
