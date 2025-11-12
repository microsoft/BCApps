// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Setup;

page 111 "Vendor Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Posting Groups';
    CardPageID = "Vendor Posting Group Card";
    PageType = List;
    SourceTable = "Vendor Posting Group";
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
                    begin
                        if ShowAllAccounts then begin
                            PmtDiscountVisible := true;
                            PmtToleranceVisible := true;
                            InvRoundingVisible := true;
                            ApplnRoundingVisible := true;
                        end else
                            Rec.SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);

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
                    ToolTip = 'Specifies an identifier for the vendor posting group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the vendor posting group.';
                }
                field("View All Accounts on Lookup"; Rec."View All Accounts on Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all possible accounts are shown when you look up from a field. If the check box is not selected, then only accounts related to the involved account category are shown.';
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
                    ToolTip = 'Specifies the general ledger account to use when you post service charges due to vendors in this posting group.';
                }
                field("Payment Disc. Debit Acc."; Rec."Payment Disc. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account to use when you post reductions in payment discounts received from vendors in this posting group.';
                    Visible = PmtDiscountVisible;
                }
                field("Payment Disc. Credit Acc."; Rec."Payment Disc. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account to use when you post payment discounts received from vendors in this posting group.';
                    Visible = PmtDiscountVisible;
                }
                field("Invoice Rounding Account"; Rec."Invoice Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account to use when amounts result from invoice rounding when you post transactions that involve vendors.';
                    Visible = InvRoundingVisible;
                }
                field("Debit Curr. Appln. Rndg. Acc."; Rec."Debit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                    Visible = ApplnRoundingVisible;
                }
                field("Credit Curr. Appln. Rndg. Acc."; Rec."Credit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to use when you post rounding differences. These differences can occur when you apply entries in different currencies to one another.';
                    Visible = ApplnRoundingVisible;
                }
                field("Debit Rounding Account"; Rec."Debit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to use when you post rounding differences from a remaining amount.';
                }
                field("Credit Rounding Account"; Rec."Credit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to use when you post rounding differences from a remaining amount.';
                }
                field("Payment Tolerance Debit Acc."; Rec."Payment Tolerance Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to use when you post purchase tolerance amounts and payments for purchases. This applies to this particular combination of business posting group and product posting group.';
                    Visible = PmtToleranceVisible;
                }
                field("Payment Tolerance Credit Acc."; Rec."Payment Tolerance Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to use when you post purchase tolerance amounts and payments for purchases. This applies to this particular combination of business posting group and product posting group.';
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
                    RunObject = Page "Alt. Vendor Posting Groups";
                    RunPageLink = "Vendor Posting Group" = field(Code);
                    ToolTip = 'Specifies alternative vendor posting groups.';
                    Visible = AltPostingGroupsVisible;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetAccountVisibility(PmtToleranceVisible, PmtDiscountVisible, InvRoundingVisible, ApplnRoundingVisible);

        PurchasesPayablesSetup.GetRecordOnce();
        AltPostingGroupsVisible := PurchasesPayablesSetup."Allow Multiple Posting Groups";
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PmtDiscountVisible: Boolean;
        PmtToleranceVisible: Boolean;
        InvRoundingVisible: Boolean;
        ApplnRoundingVisible: Boolean;
        AltPostingGroupsVisible: Boolean;
        ShowAllAccounts: Boolean;
}

