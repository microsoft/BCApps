// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

query 7440 "EA Posted Report Card Trans"
{
    Access = Internal;
    QueryType = Normal;
    DataAccessIntent = ReadWrite;

    elements
    {
        dataitem(PostedReportLine; "Posted Expense Report Line")
        {
            DataItemTableFilter = "Is Canceled" = const(false), "Credit Card Feed No." = filter(<> 0);

            filter(PostedReportNo; "Document No.") { }
            column(CreditCardFeedNo; "Credit Card Feed No.") { }

            dataitem(CorpCardTrans; "EA Corp Card Trans")
            {
                DataItemLink = "Entry No." = PostedReportLine."Credit Card Feed No.";
                SqlJoinType = LeftOuterJoin;

                column(TransactionEntryNo; "Entry No.") { }
                column(StatementEntryNo; "Statement Entry No.") { }
            }
        }
    }
}
