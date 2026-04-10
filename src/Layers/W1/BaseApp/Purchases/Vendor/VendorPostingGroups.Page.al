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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("View All Accounts on Lookup"; Rec."View All Accounts on Lookup")
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
                }
                field("Payment Disc. Debit Acc."; Rec."Payment Disc. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PmtDiscountVisible;
                }
                field("Payment Disc. Credit Acc."; Rec."Payment Disc. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PmtDiscountVisible;
                }
                field("Invoice Rounding Account"; Rec."Invoice Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = InvRoundingVisible;
                }
                field("Debit Curr. Appln. Rndg. Acc."; Rec."Debit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    Visible = ApplnRoundingVisible;
                }
                field("Credit Curr. Appln. Rndg. Acc."; Rec."Credit Curr. Appln. Rndg. Acc.")
                {
                    ApplicationArea = Suite;
                    Visible = ApplnRoundingVisible;
                }
                field("Debit Rounding Account"; Rec."Debit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Credit Rounding Account"; Rec."Credit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Tolerance Debit Acc."; Rec."Payment Tolerance Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PmtToleranceVisible;
                }
                field("Payment Tolerance Credit Acc."; Rec."Payment Tolerance Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
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

