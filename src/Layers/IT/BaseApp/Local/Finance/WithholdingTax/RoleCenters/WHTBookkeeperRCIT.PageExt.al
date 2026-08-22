// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Payment;
using Microsoft.Finance.WithholdingTax;

pageextension 12108 "WHT Bookkeeper RC IT" extends "Bookkeeper Role Center"
{
    actions
    {
        addafter("VAT Fiscal Register")
        {
            separator(Action1130014)
            {
            }
            group(Withholding)
            {
                Caption = 'Withholding';
                action("Withholding Taxes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Withholding Taxes';
                    Image = "Report";
                    RunObject = Report "Withholding Taxes";
                    ToolTip = 'View the withholding taxes.';
                }
                action(Contribution)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contribution';
                    Image = "Report";
                    RunObject = Report Contribution;
                    ToolTip = 'Get a report of social security and workers’ compensation contribution taxes on non-inventory services that you have purchased from an independent contractor or consultant.';
                }
                action("Compensation Details")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Compensation Details';
                    Image = "Report";
                    RunObject = Report "Compensation Details";
                    ToolTip = 'View the data that will be included in the Certifications report.';
                }
                action(Certifications)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certifications';
                    Image = "Report";
                    RunObject = Report Certifications;
                    ToolTip = 'View the withholding tax and social security tax that the company has paid.';
                }
            }
        }
        addafter("VAT Statements")
        {
            action(Action1130000)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withholding Taxes';
                RunObject = Page "Withholding Tax List";
                ToolTip = 'View the withholding taxes.';
            }
            action("Withholding Tax Payments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withholding Tax Payments';
                RunObject = Page "Withholding Tax Payment List";
                ToolTip = 'View the withholding tax payments.';
            }
            action("INPS Contributions")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'INPS Contributions';
                RunObject = Page "INPS Contribution List";
                ToolTip = 'View the social security taxes on non-inventory services that you have purchased from an independent contractor or consultant. ';
            }
            action("INAIL Contribution")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'INAIL Contribution';
                RunObject = Page "INAIL Contribution List";
                ToolTip = 'View the workers’ compensation taxes on non-inventory services that you have purchased from an independent contractor or consultant.';
            }
            action("INAIL & Social Security Payments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'INAIL & Social Security Payments';
                RunObject = Page "Contribution Payment List";
                ToolTip = 'View the INAIL and social security tax payments.';
            }
        }
        addafter("Calc. and Pos&t VAT Settlement")
        {
            action("Withholding Tax Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withholding Tax Card';
                Image = ListPage;
                RunObject = Page "Withholding Tax Card";
                ToolTip = 'View the  withholding tax card.';
            }
            action("Social Security")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Social Security';
                Image = SocialSecurity;
                RunObject = Page "Contribution Card";
                ToolTip = 'View the contribution taxes that have been applied to a purchase invoice from an independent contractor or consultant.';
            }
        }
    }
}