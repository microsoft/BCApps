// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Bank.Journal;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Reporting;

pageextension 11362 "Small Business Owner RC NL" extends "Small Business Owner RC"
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
                ToolTip = 'View a list of bank accounts that are set up for electronic bank file transfers using the Telebanking functionality.';
            }
        }
        addafter(GeneralJournals)
        {
            action("Bank/Giro Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank/Giro Journals';
                RunObject = Page "Bank/Giro Journal List";
                ToolTip = 'Reconcile a bank account by comparing incoming and outgoing bank transactions to a physical bank statement or by importing an electronic bank statement file, and apply the related payments to open customer or vendor documents.';
            }
            action("Cash Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Journals';
                RunObject = Page "Cash Journal List";
                ToolTip = 'Post transactions to the cash account in the general ledger.';
            }
        }
        addafter("&Bank Account Reconciliation")
        {
            action("Import Bank Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Bank Statement';
                RunObject = Codeunit "Import Protocol Management";
                ToolTip = 'Prepare to reconcile the bank account by importing an electronic bank statement with the actual bank transactions.';
            }
        }
        addafter("Calc. and Post VAT Settlem&ent")
        {
            action("Elec. Tax Declarations")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Elec. Tax Declarations';
                RunObject = Page "Elec. Tax Declaration List";
                ToolTip = 'View the list of VAT and ICP declarations that you send to the tax authorities.';
            }
            action("Elec. Tax Decl. Response Msgs.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Elec. Tax Decl. Response Msgs.';
                RunObject = Page "Elec. Tax Decl. Response Msgs.";
                ToolTip = 'View all the response messages received from the tax authorities. The status of the response message indicates if the message is processed or not.';
            }
        }
    }
}
