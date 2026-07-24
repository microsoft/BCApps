// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Journal;
using Microsoft.Finance.GeneralLedger.Journal;

pageextension 11357 "Acc. Receivables Adm. RC NL" extends "Acc. Receivables Adm. RC"
{
    actions
    {
        addafter(GeneralJournals)
        {
            action("Bank/Giro Journals")
            {
                ApplicationArea = Advanced;
                Caption = 'Bank/Giro Journals';
                RunObject = Page "Bank/Giro Journal List";
                RunPageView = where(Type = const("Bank/Giro"));
                ToolTip = 'Reconcile a bank account by comparing incoming and outgoing bank transactions to a physical bank statement or by importing an electronic bank statement file, and apply the related payments to open customer or vendor documents.';
            }
            action("Cash Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Journals';
                RunObject = Page "Cash Journal List";
                RunPageView = where(Type = const(Cash));
                ToolTip = 'Post transactions to the cash account in the general ledger.';
            }
        }
    }
}