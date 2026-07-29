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
                RunObject = page "Bank/Giro Journal List";
            }
            action("Cash Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Journal';
                RunObject = page "Cash Journal List";
            }
            action("Telebank - Bank Overview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Telebank - Bank Overview';
                RunObject = page "Telebank - Bank Overview";
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
                    RunObject = page "Elec. Tax Declaration List";
                }
                action("Elec. Tax Decl. Response Msgs.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Decl. Response Msgs.';
                    RunObject = page "Elec. Tax Decl. Response Msgs.";
                }
            }
        }
        addafter("Foreign Currency Balance")
        {
            action("Tax Authority - Audit File")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Tax Authority - Audit File';
                RunObject = report "Tax Authority - Audit File";
            }
            action("NL Export Financial Data to XM")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'NL Export Financial Data to XML';
                RunObject = report "Export Financial Data to XML";
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
                    RunObject = page "Elec. Tax Declaration Setup";
                }
                action("Elec. Tax Decl. VAT Categories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Decl. VAT Categories';
                    RunObject = page "Elec. Tax Decl. VAT Categ.";
                }
            }
            group("Group63")
            {
                Caption = 'Telebanking';
                action("Transaction Modes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Modes';
                    RunObject = page "Transaction Mode List";
                }
                action("Export Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Protocols';
                    RunObject = page "Export Protocols";
                }
                action("Import Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Protocols';
                    RunObject = page "Import Protocols";
                }
                action("Freely Transferable Maximums")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Freely Transferable Maximums';
                    RunObject = page "Freely Transferable Maximums";
                }
            }
        }
    }
}
