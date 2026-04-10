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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payables Account"; Rec."Payables Account")
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

