// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Setup;

using System.Telemetry;

page 32000000 "Bank Reference File Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Reference File Setup';
    PageType = Card;
    SourceTable = "Reference File Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a bank account code for the reference file setup information.';
                }
                field("Inform. of Appl. Cr. Memos"; Rec."Inform. of Appl. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the data of credit invoices applied to invoices to be relayed to the payee.';
                }
                field("Allow Comb. Domestic Pmts."; Rec."Allow Comb. Domestic Pmts.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to combine all domestic payments into one recipient from one day for the same bank account.';
                    Visible = false;
                }
                field("Payment Journal Template"; Rec."Payment Journal Template")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment journal template for the reference file setup information.';
                    Visible = false;
                }
                field("Payment Journal Batch"; Rec."Payment Journal Batch")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a payment journal batch for the reference setup information.';
                    Visible = false;
                }
            }
            group("Foreign Payments")
            {
                Caption = 'Foreign Payments';
                field("Due Date Handling"; Rec."Due Date Handling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date processing applied to foreign payments.';
                }
                field("Default Service Fee Code"; Rec."Default Service Fee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a foreign bank service fee code. For example, J = Payee pays foreign bank charges.';
                }
                field("Default Payment Method"; Rec."Default Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method for foreign payments. For example, M = payment order.';
                }
                field("Exchange Rate Contract No."; Rec."Exchange Rate Contract No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rate agreement number for a currency trade transaction with the bank.';
                }
                field("Allow Comb. Foreign Pmts."; Rec."Allow Comb. Foreign Pmts.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to combine foreign payments into one recipient from one day for one bank account.';
                }
            }
            group(SEPA)
            {
                Caption = 'SEPA';
                field("Bank Party ID"; Rec."Bank Party ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank party identifier for the Single Euro Payment Area (SEPA) payment file.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full path of the Single Euro Payment Area (SEPA) payment file.';
                }
                field("Allow Comb. SEPA Pmts."; Rec."Allow Comb. SEPA Pmts.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to combine SEPA payments into one receipt for one day for one bank account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FIBankTok: Label 'FI Electronic Banking', Locked = true;
    begin
        FeatureTelemetry.LogUptake('1000HN4', FIBankTok, Enum::"Feature Uptake Status"::Discovered);
    end;
}

