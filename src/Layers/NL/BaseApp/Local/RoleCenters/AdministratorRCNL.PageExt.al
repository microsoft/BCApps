// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.VAT.Reporting;


pageextension 11351 "Administrator RC NL" extends "Administrator Role Center"
{
    actions
    {
        addafter("Analysis View")
        {
            group(Telebanking)
            {
                Caption = 'Telebanking';
                action("Transaction Modes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transaction Modes';
                    RunObject = Page "Transaction Mode List";
                    ToolTip = 'View or edit the transaction modes that are used for telebanking to manage how an order, invoice, or credit memo for a vendor or customer will be paid for or collected.';
                }
                action("Export Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Protocols';
                    RunObject = Page "Export Protocols";
                    ToolTip = 'Set up codes for each set of export protocols to be used when exporting a payment history for processing by the bank.';
                }
                action("Import Protocols")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Protocols';
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
            group("Tax Declaration")
            {
                Caption = 'Tax Declaration';
                action("Elec. Tax Decl. VAT Categories")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Elec. Tax Decl. VAT Categories';
                    RunObject = Page "Elec. Tax Decl. VAT Categ.";
                    ToolTip = 'Set up all the possible combinations of categories and sub categories that represent a XML element in the electronic VAT declaration. A combination is defined by a code. By entering this code in the Elec. Tax Decl. Category Code field on a VAT statement line, you map the data of the VAT statement directly to a XML element.';
                }
            }
        }
        addafter("&General Ledger Setup")
        {
            action("Elec. Tax Declaration Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Elec. Tax Declaration Setup';
                RunObject = Page "Elec. Tax Declaration Setup";
                ToolTip = 'Set up the information that will be used to generate an electronic VAT and ICP declaration, such as the Digipoort configuration. ';
            }
        }
        addafter(SalesAnalysisColumnTmpl)
        {
            action(Action121)
            {
                ApplicationArea = Advanced;
                Caption = 'Sales Analysis View List';
                RunObject = Page "Analysis View List";
                ToolTip = 'View the list of views that you use to analyze the dynamics of your sales volumes. You can also use the report to analyze your customers'' performance and sales prices.';
            }
        }
        addafter(PurchaseAnalysisColumnTmpl)
        {
            action(Action125)
            {
                ApplicationArea = Advanced;
                Caption = 'Purchase Analysis View List';
                RunObject = Page "Analysis View List";
                ToolTip = 'View the list of views that you use to analyze the dynamics of your purchase volumes. You can also use the report to analyze your vendors'' performance and purchase prices.';
            }
        }
    }
}