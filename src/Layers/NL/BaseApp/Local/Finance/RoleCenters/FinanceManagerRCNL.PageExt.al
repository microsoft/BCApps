// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Journal;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.VAT.Reporting;

pageextension 11359 "Finance Manager RC NL" extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Account Schedules")
        {
            action("Bank/Giro Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank/Giro Journal';
                Image = Journals;
                RunObject = page "Bank/Giro Journal List";
                ToolTip = 'Reconcile a bank account by comparing incoming and outgoing bank transactions to a physical bank statement or by importing an electronic bank statement file, and apply the related payments to open customer or vendor documents.';
            }
            action("Cash Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Journal';
                Image = Journals;
                RunObject = page "Cash Journal List";
                ToolTip = 'Post transactions to the cash account in the general ledger.';
            }
            action("Telebank - Bank Overview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Telebank - Bank Overview';
                Image = BankAccount;
                RunObject = page "Telebank - Bank Overview";
                ToolTip = 'View a list of bank accounts that are set up for electronic bank file transfers.';
            }
        }
        addafter(Group1)
        {
            group("Group64")
            {
                Caption = 'Elec. Tax Declaration';
                action("Elec. Tax Declarations")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Declarations';
                    Image = VATStatement;
                    RunObject = page "Elec. Tax Declaration List";
                    ToolTip = 'View the list of VAT and ICP declarations that you send to the tax authorities.';
                }
                action("Elec. Tax Decl. Response Msgs.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Decl. Response Msgs.';
                    Image = VATStatement;
                    RunObject = page "Elec. Tax Decl. Response Msgs.";
                    ToolTip = 'View all the response messages received from the tax authorities. The status of the response message indicates if the message is processed or not.';
                }
            }
        }
        addafter("Foreign Currency Balance")
        {
            action("Tax Authority - Audit File")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tax Authority - Audit File';
                Image = Report;
                RunObject = report "Tax Authority - Audit File";
                ToolTip = 'Create an audit file that contains all journal transactions from the general ledger. During a tax audit, this file is imported from the tax authority for additional analysis.';
            }
            action("NL Export Financial Data to XM")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'NL Export Financial Data to XML';
                Image = Export;
                RunObject = report "Export Financial Data to XML";
                ToolTip = 'Export financial data to an XML file.';
            }
        }
        addafter("VAT Report Setup")
        {
            group("Group62")
            {
                Caption = 'Elec. Tax Declaration';
                action("Elec. Tax Declaration Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Declaration Setup';
                    Image = Setup;
                    RunObject = page "Elec. Tax Declaration Setup";
                    ToolTip = 'Set up the information that will be used to generate an electronic VAT and ICP declaration, such as the Digipoort configuration.';
                }
                action("Elec. Tax Decl. VAT Categories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Decl. VAT Categories';
                    Image = SetupList;
                    RunObject = page "Elec. Tax Decl. VAT Categ.";
                    ToolTip = 'Set up all the possible combinations of categories and subcategories that represent an XML element in the electronic VAT declaration.';
                }
            }
            group("Group63")
            {
                Caption = 'Telebanking';
                action("Transaction Modes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Modes';
                    Image = SetupList;
                    RunObject = page "Transaction Mode List";
                    ToolTip = 'View or edit the transaction modes that are used for telebanking to manage how an order, invoice, or credit memo for a vendor or customer will be paid for or collected.';
                }
                action("Export Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Protocols';
                    Image = Export;
                    RunObject = page "Export Protocols";
                    ToolTip = 'Set up codes for each set of export protocols to be used when exporting a payment history for processing by the bank.';
                }
                action("Import Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Protocols';
                    Image = Import;
                    RunObject = page "Import Protocols";
                    ToolTip = 'Set up codes for each set of import protocols to be used when importing bank statements.';
                }
                action("Freely Transferable Maximums")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Freely Transferable Maximums';
                    Image = SetupList;
                    RunObject = page "Freely Transferable Maximums";
                    ToolTip = 'Set up freely transferable maximums that denote the maximum amount, for a specific currency, that can be transferred in one payment from one country to another without reason given.';
                }
            }
        }
    }
}
