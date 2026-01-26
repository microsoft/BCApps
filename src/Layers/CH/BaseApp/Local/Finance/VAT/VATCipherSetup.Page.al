// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

page 11024 "VAT Cipher Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Cipher Setup';
    SourceTable = "VAT Cipher Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Revenue)
            {
                Caption = 'Revenue';
                field("Total Revenue"; Rec."Total Revenue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for total amount of agreed or collected consideration.';
                }
                field("Revenue of Non-Tax. Services"; Rec."Revenue of Non-Tax. Services")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for revenue of non-taxable services.';
                }
                field("Deduction of Tax-Exempt"; Rec."Deduction of Tax-Exempt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for deduction of tax-exempt services.';
                }
                field("Deduction of Services Abroad"; Rec."Deduction of Services Abroad")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for deduction of services abroad.';
                }
                field("Deduction of Transfer"; Rec."Deduction of Transfer")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for deduction of transfer.';
                }
                field("Deduction of Non-Tax. Services"; Rec."Deduction of Non-Tax. Services")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for deduction of non-taxable services.';
                }
                field("Reduction in Payments"; Rec."Reduction in Payments")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for reduction in payments.';
                }
                field(Miscellaneous; Rec.Miscellaneous)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for miscellaneous taxation.';
                }
                field("Total Deductions"; Rec."Total Deductions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for total deductions.';
                }
                field("Total Taxable Revenue"; Rec."Total Taxable Revenue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for total taxable turnover.';
                }
            }
            group("Tax Computation")
            {
                Caption = 'Tax Computation';
                field("Tax Normal Rate Serv. Before"; Rec."Tax Normal Rate Serv. Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for tax services at normal rate before period.';
                }
                field("Tax Reduced Rate Serv. Before"; Rec."Tax Reduced Rate Serv. Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for tax services at reduced rate before period.';
                }
                field("Tax Hotel Rate Serv. Before"; Rec."Tax Hotel Rate Serv. Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for tax services at hotel rate before period.';
                }
                field("Acquisition Tax Before"; Rec."Acquisition Tax Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for acquisition tax before period.';
                }
                field("Total Owned Tax"; Rec."Total Owned Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for total owned tax.';
                }
                field("Tax Normal Rate Serv. After"; Rec."Tax Normal Rate Serv. After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for tax services at normal rate inside period.';
                }
                field("Tax Reduced Rate Serv. After"; Rec."Tax Reduced Rate Serv. After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for tax services at reduced rate inside period.';
                }
                field("Tax Hotel Rate Serv. After"; Rec."Tax Hotel Rate Serv. After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for tax services at hotel rate inside period.';
                }
                field("Acquisition Tax After"; Rec."Acquisition Tax After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for acquisition tax inside period.';
                }
            }
            group("Input Tax")
            {
                Caption = 'Input Tax';
                field("Input Tax on Material and Serv"; Rec."Input Tax on Material and Serv")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for input tax on cost of materials and services.';
                }
                field("Input Tax on Investsments"; Rec."Input Tax on Investsments")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for input tax on investments.';
                }
                field("Deposit Tax"; Rec."Deposit Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for de-taxation.';
                }
                field("Input Tax Corrections"; Rec."Input Tax Corrections")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for correction of the input tax deduction.';
                }
                field("Input Tax Cutbacks"; Rec."Input Tax Cutbacks")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for reduction of the input tax deduction.';
                }
                field("Total Input Tax"; Rec."Total Input Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for total amount of tax due.';
                }
                field("Tax Amount to Pay"; Rec."Tax Amount to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for amount to be paid.';
                }
                field("Credit of Taxable Person"; Rec."Credit of Taxable Person")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for credit in favour of the taxable person.';
                }
            }
            group("Other Cash Flow")
            {
                Caption = 'Other Cash Flow';
                field("Cash Flow Taxes"; Rec."Cash Flow Taxes")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for cash flow taxes: subsidies, funds.';
                }
                field("Cash Flow Compensations"; Rec."Cash Flow Compensations")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for cash flow compensations: donations, dividends.';
                }
            }
        }
    }

    actions
    {
    }
}

