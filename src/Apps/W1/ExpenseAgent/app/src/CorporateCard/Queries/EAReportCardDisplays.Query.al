// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

query 7441 "EA Report Card Displays"
{
    Access = Internal;
    QueryType = Normal;

    elements
    {
        dataitem(ReportLine; "Expense Report Line")
        {
            DataItemTableFilter = "Corporate Card Id" = filter(<> '');

            filter(DocumentNo; "Document No.") { }

            dataitem(CorpCard; "EA Corp Card")
            {
                DataItemLink = "Card Id" = ReportLine."Corporate Card Id";
                SqlJoinType = InnerJoin;

                column(CardId; "Card Id") { }
                column(ProviderCode; "Provider Code") { }
                column(MaskedCardNo; "Masked Card No.") { }

                dataitem(Provider; "EA Corp Card Provider")
                {
                    DataItemLink = Code = CorpCard."Provider Code";
                    SqlJoinType = LeftOuterJoin;

                    column(ProviderShortName; "Short Name") { }
                }
            }
        }
    }
}
