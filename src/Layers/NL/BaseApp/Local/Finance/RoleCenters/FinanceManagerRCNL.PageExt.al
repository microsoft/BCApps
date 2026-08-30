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
                Tooltip = 'Manage the bank/giro journal entries.';
            }
            action("Cash Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Journal';
                Image = Journals;
                RunObject = page "Cash Journal List";
                Tooltip = 'Manage the cash journal entries.';
            }
            action("Telebank - Bank Overview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Telebank - Bank Overview';
                Image = Bank;
                RunObject = page "Telebank - Bank Overview";
                Tooltip = 'View the overview of telebanking bank accounts.';
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
                    Image = CalculateVAT;
                    RunObject = page "Elec. Tax Declaration List";
                    Tooltip = 'Manage the electronic tax declarations.';
                }
                action("Elec. Tax Decl. Response Msgs.")
                {
                    ApplicationArea = Basic, Suite;
                    Image = CalculateVAT;
                    Caption = 'Elec. Tax Decl. Response Msgs.';
                    RunObject = page "Elec. Tax Decl. Response Msgs.";
                    Tooltip = 'View the response messages for electronic tax declarations.';
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
                Tooltip = 'Generate the audit file for the tax authority.';
            }
            action("NL Export Financial Data to XM")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'NL Export Financial Data to XML';
                Image = Export;
                RunObject = report "Export Financial Data to XML";
                Tooltip = 'Export the financial data to an XML file.';
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
                    Image = CalculateVAT;
                    RunObject = page "Elec. Tax Declaration Setup";
                    Tooltip = 'Configure the electronic tax declaration settings.';
                }
                action("Elec. Tax Decl. VAT Categories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Decl. VAT Categories';
                    Image = CalculateVAT;
                    RunObject = page "Elec. Tax Decl. VAT Categ.";
                    Tooltip = 'Manage the VAT categories for electronic tax declarations.';
                }
            }
            group("Group63")
            {
                Caption = 'Telebanking';
                action("Transaction Modes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Modes';
                    Image = Setup;
                    RunObject = page "Transaction Mode List";
                    Tooltip = 'Manage the transaction modes for telebanking.';
                }
                action("Export Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Protocols';
                    Image = Export;
                    RunObject = page "Export Protocols";
                    Tooltip = 'Manage the export protocols for telebanking.';
                }
                action("Import Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Protocols';
                    Image = Import;
                    RunObject = page "Import Protocols";
                    Tooltip = 'Manage the import protocols for telebanking.';
                }
                action("Freely Transferable Maximums")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Freely Transferable Maximums';
                    Image = Setup;
                    RunObject = page "Freely Transferable Maximums";
                    Tooltip = 'Manage the freely transferable maximums for telebanking.';
                }
            }
        }
    }
}
