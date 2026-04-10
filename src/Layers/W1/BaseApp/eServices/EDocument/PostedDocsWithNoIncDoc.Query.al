// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Ledger;

query 130 "Posted Docs. With No Inc. Doc."
{
    Caption = 'Posted Docs. With No Inc. Doc.';

    elements
    {
        dataitem(G_L_Entry; "G/L Entry")
        {
            filter(GLAccount; "G/L Account No.")
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(DocumentNo; "Document No.")
            {
            }
            column(ExternalDocumentNo; "External Document No.")
            {
            }
            column(DebitAmount; "Debit Amount")
            {
                Method = Sum;
            }
            column(CreditAmount; "Credit Amount")
            {
                Method = Sum;
            }
            column(NoOfEntries)
            {
                Method = Count;
            }
            dataitem(Incoming_Document; "Incoming Document")
            {
                DataItemLink = "Document No." = G_L_Entry."Document No.", "Posting Date" = G_L_Entry."Posting Date";
                column(NoOfIncomingDocuments)
                {
                    ColumnFilter = NoOfIncomingDocuments = const(0);
                    Method = Count;
                }
            }
        }
    }
}

