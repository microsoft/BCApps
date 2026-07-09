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
                }
                action("Calc. and Post WHT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calc. and Post WHT Settlement';
                    RunObject = Report "Calc. and Post WHT Settlement";
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
            }
            action("WHT PND 2")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 2';
                RunObject = Report "WHT PND 2";
            }
            action("WHT PND 3")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT PND 3';
                RunObject = Report "WHT PND 3";
            }
            action("WHT Report - PND 53")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Report - PND 53';
                RunObject = Report "WHT Report - PND 53";
            }
            action("WHT Certificate - Other Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Other Copy';
                RunObject = Report "WHT Certificate - Other Copy";
            }
            action("WHT Certificate TH - Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate TH - Copy';
                RunObject = Report "WHT Certificate TH - Copy";
            }
        }
        addafter("VAT Report - Customer1")
        {
            action("WHT Certificate - Copy")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Copy';
                RunObject = Report "WHT Certificate - Other Copy";
            }
        }
        addafter("VAT Report - Vendor1")
        {
            action("WHT Certificate - Copy1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Certificate - Copy';
                RunObject = Report "WHT Certificate - Other Copy";
            }
        }
        addafter("Product Posting Groups")
        {
            action("Business")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Business Posting Group';
                RunObject = page "WHT Business Posting Group";
            }
            action("Product")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Product Posting Group';
                RunObject = page "WHT Product Posting Group";
            }
            action("Revenue Types")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Revenue Types';
                RunObject = page "WHT Revenue Types";
            }
            action("Posting Setup1")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'WHT Posting Setup';
                RunObject = page "WHT Posting Setup";
            }
        }
    }
}
