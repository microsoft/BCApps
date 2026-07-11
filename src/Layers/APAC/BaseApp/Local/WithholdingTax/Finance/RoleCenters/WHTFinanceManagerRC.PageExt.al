// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.RoleCenters;

pageextension 28009 WHTFinanceManagerRC extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Group2")
        {
            group("Group3")
            {
                Caption = 'WHT';
                action("WHT E-Filing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'WHT E-Filing';
                    RunObject = Report "WHT E-Filing";
                    Tooltip = 'Open the WHT E-Filing report.';
                }
                action("Calc. and Post WHT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calc. and Post WHT Settlement';
                    RunObject = Report "Calc. and Post WHT Settlement";
                    Tooltip = 'Open the Calc. and Post WHT Settlement report.';
                }
            }
        }
        addafter("Bank Detail Cashflow Compare")
        {
            action("WHT PND 1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 1';
                RunObject = Report "WHT PND 1";
                Tooltip = 'Open the WHT PND 1 report.';
            }
            action("WHT PND 2")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 2';
                RunObject = Report "WHT PND 2";
                Tooltip = 'Open the WHT PND 2 report.';
            }
            action("WHT PND 3")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 3';
                RunObject = Report "WHT PND 3";
                Tooltip = 'Open the WHT PND 3 report.';
            }
            action("WHT Report - PND 53")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Report - PND 53';
                RunObject = Report "WHT Report - PND 53";
                Tooltip = 'Open the WHT Report - PND 53 report.';
            }
            action("WHT Certificate - Other Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Other Copy';
                RunObject = Report "WHT Certificate - Other Copy";
                Tooltip = 'Open the WHT Certificate - Other Copy report.';
            }
            action("WHT Certificate TH - Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate TH - Copy';
                RunObject = Report "WHT Certificate TH - Copy";
                Tooltip = 'Open the WHT Certificate TH - Copy report.';
            }
        }
        addafter("VAT Report - Customer1")
        {
            action("WHT Certificate - Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Copy';
                RunObject = Report "WHT Certificate - Other Copy";
                Tooltip = 'Open the WHT Certificate - Copy report.';
            }
        }
        addafter("VAT Report - Vendor1")
        {
            action("WHT Certificate - Copy1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Copy';
                RunObject = Report "WHT Certificate - Other Copy";
                Tooltip = 'Open the WHT Certificate - Copy report.';
            }
        }
        addafter("Product Posting Groups")
        {
            action("Business")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Business Posting Group';
                RunObject = page "WHT Business Posting Group";
                Tooltip = 'Open the WHT Business Posting Group page.';
            }
            action("Product")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Product Posting Group';
                RunObject = page "WHT Product Posting Group";
                Tooltip = 'Open the WHT Product Posting Group page.';
            }
            action("Revenue Types")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Revenue Types';
                RunObject = page "WHT Revenue Types";
                Tooltip = 'Open the WHT Revenue Types page.';
            }
            action("Posting Setup1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Posting Setup';
                RunObject = page "WHT Posting Setup";
                Tooltip = 'Open the WHT Posting Setup page.';
            }
        }
        addafter("Financial Analysis Report")
        {
            action("Withholding Summary")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withholding Summary';
                RunObject = Report "Withholding Summary";
                Tooltip = 'Open the Withholding Summary report.';
            }
        }
        addafter("Posted Return Receipts")
        {
            action("Posted Sales Tax Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Sales Tax Invoice';
                RunObject = page "Posted Sales Tax Invoice";
                Tooltip = 'Open the Posted Sales Tax Invoice page.';
            }
            action("Posted Sales Tax Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Sales Tax Credit Memo';
                RunObject = page "Posted Sales Tax Credit Memo";
                Tooltip = 'Open the Posted Sales Tax Credit Memo page.';
            }
        }
        addafter("VAT Report - Customer1")
        {
            action("Pending Sales Tax Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pending Sales Tax Invoice';
                RunObject = Report "Pending Sales Tax Invoice";
                Tooltip = 'Open the Pending Sales Tax Invoice report.';
            }
        }
        addafter("Posted Return Shipments")
        {
            action("Posted Purchase Tax Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Purchase Tax Invoice';
                RunObject = page "Posted Purchase Tax Invoice";
                Tooltip = 'Open the Posted Purchase Tax Invoice page.';
            }
            action("Posted Purch. Tax  Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Purch. Tax  Credit Memo';
                RunObject = page "Posted Purch. Tax  Credit Memo";
                Tooltip = 'Open the Posted Purchase Tax Credit Memo page.';
            }
        }
    }
}
