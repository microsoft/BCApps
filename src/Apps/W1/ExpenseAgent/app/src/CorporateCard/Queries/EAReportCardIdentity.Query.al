// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

query 7444 "EA Report Card Identity"
{
    Access = Internal;
    QueryType = Normal;
    DataAccessIntent = ReadWrite;

    elements
    {
        dataitem(ReportLine; "Expense Report Line")
        {
            DataItemTableFilter = "Corporate Card Id" = const(''), "Credit Card Feed No." = filter(<> 0);

            column(FeedEntryNo; "Credit Card Feed No.") { }

            dataitem(CorpCardTrans; "EA Corp Card Trans")
            {
                DataItemLink = "Entry No." = ReportLine."Credit Card Feed No.";
                SqlJoinType = InnerJoin;

                column(CardId; "Card Id") { }
                // Group repeated feed links into one update.
                column(LinkedRowCount) { Method = Count; }
            }
        }
    }
}
