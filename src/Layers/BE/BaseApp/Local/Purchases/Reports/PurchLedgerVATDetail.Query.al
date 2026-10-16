// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;

query 11302 "Purch. Ledger VAT Detail"
{
    QueryType = Normal;
    Caption = 'Purchase Ledger VAT Detail';

    elements
    {
        dataitem(G_L_Entry; "G/L Entry")
        {
            column(GLEntryNo; "Entry No.")
            {
            }
            filter(JournalTemplName; "Journal Templ. Name")
            {
            }
            filter(PostingDate; "Posting Date")
            {
            }
            filter(VATReportingDate; "VAT Reporting Date")
            {
            }
            dataitem(Link; "G/L Entry - VAT Entry Link")
            {
                DataItemLink = "G/L Entry No." = G_L_Entry."Entry No.";
                SqlJoinType = InnerJoin;
                dataitem(VAT_Entry; "VAT Entry")
                {
                    DataItemLink = "Entry No." = Link."VAT Entry No.";
                    SqlJoinType = InnerJoin;
                    column(MatchedCount; "Entry No.")
                    {
                        Method = Count;
                    }
                    column(BaseSum; Base)
                    {
                        Method = Sum;
                    }
                    column(AmountSum; Amount)
                    {
                        Method = Sum;
                    }
                }
            }
        }
    }
}
