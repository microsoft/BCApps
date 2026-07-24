// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Journal;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;

pageextension 11356 "Acc. Payables Coord. RC NL" extends "Acc. Payables Coordinator RC"
{
    actions
    {
        addafter(Items)
        {
            action(Telebanking)
            {
                ApplicationArea = Advanced;
                Caption = 'Telebanking';
                RunObject = Page "Telebank - Bank Overview";
                ToolTip = 'Prepare to exchange your payments to vendors and collections from customers with your bank electronically. This includes the export of payment and collection data that need to be forwarded to the bank as well as the import of bank statements sent to you by the bank.';
            }
            action("Telebank - Bank Overview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Telebank - Bank Overview';
                RunObject = Page "Telebank - Bank Overview";
                ToolTip = 'View a list of bank accounts that are set up for electronic bank file transfers.';
            }
        }
        addafter(GeneralJournals)
        {
            action("Bank/Giro Journals")
            {
                ApplicationArea = Basic, Suite;
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
        addafter(VendorPayments)
        {
            action("Bank/Giro Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank/Giro Journal';
                RunObject = Page "Bank/Giro Journal List";
                ToolTip = 'Reconcile a bank account by comparing incoming and outgoing bank transactions to a physical bank statement or by importing an electronic bank statement file, and apply the related payments to open customer or vendor documents.';
            }
            action("Cash Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Journal';
                RunObject = Page "Cash Journal List";
                ToolTip = 'Post transactions to the cash account in the general ledger.';
            }
        }
    }
}