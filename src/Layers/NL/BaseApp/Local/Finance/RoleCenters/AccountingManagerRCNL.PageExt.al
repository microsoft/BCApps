// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Journal;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Reporting;

pageextension 11355 "Accounting Manager RC NL" extends "Accounting Manager Role Center"
{
    actions
    {
        addafter("Finance Charge Memos")
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
        addafter("Bank Account Posting Groups")
        {
            action("Elec. Tax Decl. VAT Categories")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Elec. Tax Decl. VAT Categories';
                RunObject = Page "Elec. Tax Decl. VAT Categ.";
                ToolTip = 'Set up all the possible combinations of categories and sub categories that represent a XML element in the electronic VAT declaration. A combination is defined by a code. By entering this code in the Elec. Tax Decl. Category Code field on a VAT statement line, you map the data of the VAT statement directly to a XML element.';
            }
            action("Transaction Modes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Transaction Modes';
                RunObject = Page "Transaction Mode List";
                ToolTip = 'View or edit the transaction modes that are used for telebanking to manage how an order, invoice, or credit memo for a vendor or customer will be paid for or collected.';
            }
            action("Export Telebanking Protocols")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Telebanking Protocols';
                RunObject = Page "Export Protocols";
                ToolTip = 'Set up codes for each set of export protocols to be used when exporting a payment history for processing by the bank.';
            }
            action("Import Telebanking Protocols")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Telebanking Protocols';
                RunObject = Page "Import Protocols";
                ToolTip = 'Set up codes for each set of import protocols to be used when importing bank statements.';
            }
            action("Freely Transferable Maximums")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Freely Transferable Maximums';
                RunObject = Page "Freely Transferable Maximums";
                ToolTip = 'Set up freely transferable maximums that denote the maximum amount, for a specific currency, that can be transferred in one payment from one country to another without reason given.';
            }
        }
        addafter("Import Co&nsolidation from Database")
        {
            action("Import Bank Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Bank Statement';
                RunObject = Codeunit "Import Protocol Management";
                ToolTip = 'Prepare to reconcile the bank account by importing an electronic bank statement with the actual bank transactions.';
            }
        }
        addafter("P&ost Inventory Cost to G/L")
        {
            action("Tax Authority - Audit File")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tax Authority - Audit File';
                Image = "Report";
                RunObject = Report "Tax Authority - Audit File";
                ToolTip = 'Create an audit file that contains all journal transactions from the general ledger. During a tax audit, this file is imported from the tax authority for additional analysis.';
            }
        }
        addafter("Calc. and Pos&t VAT Settlement")
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
        addafter("General &Ledger Setup")
        {
            action("Elec. Tax Declaration Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Elec. Tax Declaration Setup';
                RunObject = Page "Elec. Tax Declaration Setup";
                ToolTip = 'Set up the information that will be used to generate an electronic VAT and ICP declaration, such as the Digipoort configuration. ';
            }
        }
    }
}