// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;

page 110 "Customer Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Posting Groups';
    CardPageID = "Customer Posting Group Card";
    PageType = List;
    SourceTable = "Customer Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control5)
            {
                ShowCaption = false;
                field(ShowAllAccounts; ShowAllAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All Accounts';
                    ToolTip = 'Specifies that all possible setup fields related to G/L accounts are shown.';

                    trigger OnValidate()
                    var
                        ReminderTerms: Record "Reminder Terms";
                    begin
                        if ShowAllAccounts then begin
                            PmtDiscountVisible := true;
                            PmtToleranceVisible := true;
                            InvRoundingVisible := true;
                            ApplnRoundingVisible := true;
                            InterestAccountVisible := true;
                            AddFeeAccountVisible := true;
                            AddFeePerLineAccountVisible := true;
                        end else begin
                            Rec.SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);
                            ReminderTerms.SetAccountVisibility(InterestAccountVisible, AddFeeAccountVisible, AddFeePerLineAccountVisible);
                            UpdateAccountVisibilityBasedOnFinChargeTerms(InterestAccountVisible, AddFeeAccountVisible);
                        end;

                        CurrPage.Update();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("View All Accounts on Lookup"; Rec."View All Accounts on Lookup")
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
                field("Invoice Rounding Account"; Rec."Invoice Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = InvRoundingVisible;
                }
                field("Debit Curr. Appln. Rndg. Acc."; Rec."Debit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = ApplnRoundingVisible;
                }
                field("Credit Curr. Appln. Rndg. Acc."; Rec."Credit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = ApplnRoundingVisible;
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
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Posting Group")
            {
                Caption = '&Posting Group';
                action(Alternative)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Alternative Groups';
                    Image = Relationship;
                    RunObject = Page "Alt. Customer Posting Groups";
                    RunPageLink = "Customer Posting Group" = field(Code);
                    ToolTip = 'Specifies alternative customer posting groups.';
                    Visible = AltPostingGroupsVisible;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        Rec.SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);
        ReminderTerms.SetAccountVisibility(InterestAccountVisible, AddFeeAccountVisible, AddFeePerLineAccountVisible);
        UpdateAccountVisibilityBasedOnFinChargeTerms(InterestAccountVisible, AddFeeAccountVisible);
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PmtDiscountVisible: Boolean;
        PmtToleranceVisible: Boolean;
        InvRoundingVisible: Boolean;
        ApplnRoundingVisible: Boolean;
        InterestAccountVisible: Boolean;
        AddFeeAccountVisible: Boolean;
        AddFeePerLineAccountVisible: Boolean;
        AltPostingGroupsVisible: Boolean;
        ShowAllAccounts: Boolean;

    local procedure UpdateAccountVisibilityBasedOnFinChargeTerms(var InterestAccountVisible: Boolean; var AddFeeAccountVisible: Boolean)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.SetRange("Post Interest", true);
        InterestAccountVisible := InterestAccountVisible or not FinanceChargeTerms.IsEmpty();

        FinanceChargeTerms.SetRange("Post Interest");
        FinanceChargeTerms.SetRange("Post Additional Fee", true);
        AddFeeAccountVisible := AddFeeAccountVisible or not FinanceChargeTerms.IsEmpty();

        SalesReceivablesSetup.GetRecordOnce();
        AltPostingGroupsVisible := SalesReceivablesSetup."Allow Multiple Posting Groups";
    end;
}

