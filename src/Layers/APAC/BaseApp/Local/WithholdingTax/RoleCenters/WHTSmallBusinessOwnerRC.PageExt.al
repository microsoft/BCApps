// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.RoleCenters;

pageextension 28004 WHTSmallBusinessOwnerRC extends "Small Business Owner RC"
{
    actions
    {
        addafter("EC Sal&es List")
        {
            separator(Action1500017)
            {
            }
            action("WHT PND 1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 1';
                Image = "Report";
                RunObject = Report "WHT PND 1";
                ToolTip = 'Open the WHT PND 1 report.';
            }
            action("WHT PND 2")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 2';
                Image = "Report";
                RunObject = Report "WHT PND 2";
                ToolTip = 'Open the WHT PND 2 report.';
            }
            action("WHT PND 3")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 3';
                Image = "Report";
                RunObject = Report "WHT PND 3";
                ToolTip = 'Open the WHT PND 3 report.';
            }
            action("WHT PND 53")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 53';
                Image = "Report";
                RunObject = Report "WHT Report - PND 53";
                ToolTip = 'Open the WHT PND 53 report.';
            }
            action("Certificate of Creditable tax")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Certificate of Creditable tax';
                Image = "Report";
                RunObject = Report "Certificate of Creditable tax";
                ToolTip = 'Start the process of submitting the certificate of creditable tax.';
            }
            action("Monthly Remittance Return WHT")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Monthly Remittance Return WHT';
                Image = "Report";
                RunObject = Report "Monthly Remittance Return  WHT";
                ToolTip = 'Start the process of creating the monthly remittance return for withholding tax.';
            }
            action("E-Filing")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Filing';
                Image = "Report";
                RunObject = Report "E-Filing";
                ToolTip = 'Start the electronic submission of withholding tax report.';
            }
        }
        addafter("Posted Purchase Credit Memos")
        {
            action("Posted Sales Tax Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Sales Tax Invoices';
                RunObject = Page "Posted Sales Tax Invoices";
                ToolTip = 'View the list of posted documents.';
            }
            action("Posted Sales Tax Credit Memos")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Sales Tax Credit Memos';
                RunObject = Page "Posted Sales Tax Cr. Memos";
                ToolTip = 'View the list of posted documents.';
            }
            action("Posted Purch. Tax Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Purch. Tax Invoices';
                RunObject = Page "Posted Purch. Tax Invoices";
                ToolTip = 'View the list of posted documents.';
            }
            action("Posted Purch. Tax Credit Memos")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Purch. Tax Credit Memos';
                RunObject = Page "Posted Purch. Tax Cr. Memos";
                ToolTip = 'View the list of posted documents.';
            }
        }
        addafter("Calc. and Post VAT Settlem&ent")
        {
            action("Calc. and Post WHT Settlement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calc. and Post WHT Settlement';
                Image = "Report";
                RunObject = Report "Calc. and Post WHT Settlement";
                ToolTip = 'Start the process of calculating and posting the withholding tax settlement.';
            }
        }
    }
}
