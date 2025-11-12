// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Reminder;

page 148 "Customer Posting Group Card"
{
    Caption = 'Customer Posting Group Card';
    PageType = Card;
    SourceTable = "Customer Posting Group";

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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Receivables Account"; Rec."Receivables Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field("Service Charge Acc."; Rec."Service Charge Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                group(Discounts)
                {
                    Caption = 'Discounts';
                    field("Payment Disc. Debit Acc."; Rec."Payment Disc. Debit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = PmtDiscountVisible;
                    }
                    field("Payment Disc. Credit Acc."; Rec."Payment Disc. Credit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = PmtDiscountVisible;
                    }
                    field("Payment Tolerance Debit Acc."; Rec."Payment Tolerance Debit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = PmtToleranceVisible;
                    }
                    field("Payment Tolerance Credit Acc."; Rec."Payment Tolerance Credit Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
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
                        Visible = InvRoundingVisible;
                    }
                    field("Debit Rounding Account"; Rec."Debit Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                    }
                    field("Credit Rounding Account"; Rec."Credit Rounding Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                    }
                    field("Debit Curr. Appln. Rndg. Acc."; Rec."Debit Curr. Appln. Rndg. Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = ApplnRoundingVisible;
                    }
                    field("Credit Curr. Appln. Rndg. Acc."; Rec."Credit Curr. Appln. Rndg. Acc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = ApplnRoundingVisible;
                    }
                }
                group(Reminders)
                {
                    Caption = 'Reminders';
                    field("Interest Account"; Rec."Interest Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = InterestAccountVisible;
                    }
                    field("Additional Fee Account"; Rec."Additional Fee Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = AddFeeAccountVisible;
                    }
                    field("Add. Fee per Line Account"; Rec."Add. Fee per Line Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = AddFeePerLineAccountVisible;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        Rec.SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);
        ReminderTerms.SetAccountVisibility(InterestAccountVisible, AddFeeAccountVisible, AddFeePerLineAccountVisible);
    end;

    var
        PmtDiscountVisible: Boolean;
        PmtToleranceVisible: Boolean;
        InvRoundingVisible: Boolean;
        ApplnRoundingVisible: Boolean;
        InterestAccountVisible: Boolean;
        AddFeeAccountVisible: Boolean;
        AddFeePerLineAccountVisible: Boolean;
}

