// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 149 "Vendor Posting Group Card"
{
    Caption = 'Vendor Posting Group Card';
    PageType = Card;
    SourceTable = "Vendor Posting Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identifier for the vendor posting group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the vendor posting group.';
                }
                field("Payables Account"; Rec."Payables Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the general ledger account to use when you post payables due to vendors in this posting group.';
                }
                field("Service Charge Acc."; Rec."Service Charge Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account to use when you post service charges due to vendors in this posting group.';
                }
                group(Discounts)
                {
                    Caption = 'Discounts';
                    field("Payment Disc. Debit Acc."; Rec."Payment Disc. Debit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post reductions in payment discounts received from vendors in this posting group.';
                        Visible = PmtDiscountVisible;
                    }
                    field("Payment Disc. Credit Acc."; Rec."Payment Disc. Credit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post payment discounts received from vendors in this posting group.';
                        Visible = PmtDiscountVisible;
                    }
                    field("Payment Tolerance Debit Acc."; Rec."Payment Tolerance Debit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to use when you post purchase tolerance amounts and payments for purchases. This applies to this particular combination of business posting group and product posting group.';
                        Visible = PmtToleranceVisible;
                    }
                    field("Payment Tolerance Credit Acc."; Rec."Payment Tolerance Credit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to use when you post purchase tolerance amounts and payments for purchases. This applies to this particular combination of business posting group and product posting group.';
                        Visible = PmtToleranceVisible;
                    }
                }
                group(Rounding)
                {
                    Caption = 'Rounding';
                    field("Invoice Rounding Account"; Rec."Invoice Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when amounts result from invoice rounding when you post transactions that involve vendors.';
                        Visible = InvRoundingVisible;
                    }
                    field("Debit Rounding Account"; Rec."Debit Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to use when you post rounding differences from a remaining amount.';
                    }
                    field("Credit Rounding Account"; Rec."Credit Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account number to use when you post rounding differences from a remaining amount.';
                    }
                    field("Debit Curr. Appln. Rndg. Acc."; Rec."Debit Curr. Appln. Rndg. Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                        Visible = ApplnRoundingVisible;
                    }
                    field("Credit Curr. Appln. Rndg. Acc."; Rec."Credit Curr. Appln. Rndg. Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                        Visible = ApplnRoundingVisible;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);
    end;

    var
        PmtDiscountVisible: Boolean;
        PmtToleranceVisible: Boolean;
        InvRoundingVisible: Boolean;
        ApplnRoundingVisible: Boolean;
}

