// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Calculation;

/// <summary>
/// VAT posting setup card page for detailed configuration of specific VAT business and product posting group combinations.
/// Provides comprehensive interface for setting VAT rates, G/L account assignments, calculation methods, and non-deductible VAT options.
/// </summary>
/// <remarks>
/// Key functionality: Configure VAT percentage, unrealized VAT handling, account assignments for sales/purchase/reverse charge scenarios.
/// Advanced features: Non-deductible VAT percentage and account setup, VAT clause assignments, EU service indicators.
/// User workflow: Access from VAT Posting Setup list to configure detailed settings for specific posting group combinations.
/// </remarks>
page 473 "VAT Posting Setup Card"
{
    Caption = 'VAT Posting Setup Card';
    DataCaptionFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
    PageType = Card;
    SourceTable = "VAT Posting Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for this particular combination of VAT business posting group and VAT product posting group.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Non-Deductible VAT"; Rec."Allow Non-Deductible VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = NonDeductibleVATVisible;
                }
                field("Non-Deductible VAT %"; Rec."Non-Deductible VAT %")
                {
                    ApplicationArea = VAT;
                    Visible = NonDeductibleVATVisible;
                }
                field("Unrealized VAT Type"; Rec."Unrealized VAT Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UnrealizedVATVisible;
                }
                field("VAT Identifier"; Rec."VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Clause Code"; Rec."VAT Clause Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Adjust for Payment Discount"; Rec."Adjust for Payment Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AdjustForPmtDiscVisible;
                }
                field("VAT Exempt"; Rec."VAT Exempt")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if entries that use this posting setup are VAT exempt.';
                }
                field("Not Include into VAT Ledger"; Rec."Not Include into VAT Ledger")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if entries that use this posting setup must be excluded from the VAT ledgers for purchases and sales.';
                }
                field("Certificate of Supply Required"; Rec."Certificate of Supply Required")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Category"; Rec."Tax Category")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales VAT Account"; Rec."Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales VAT Unreal. Account"; Rec."Sales VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UnrealizedVATVisible;
                }
                field("Trans. VAT Type"; Rec."Trans. VAT Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the rule for extracting VAT.';
                }
                field("Trans. VAT Account"; Rec."Trans. VAT Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies an account in which to register the VAT amount from the gain and from the customer''s prepayments.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purchase VAT Account"; Rec."Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Non-Ded. Purchase VAT Account"; Rec."Non-Ded. Purchase VAT Account")
                {
                    ApplicationArea = VAT;
                    Visible = NonDeductibleVATVisible;
                }
                field("Purch. VAT Unreal. Account"; Rec."Purch. VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UnrealizedVATVisible;
                }
                field("Reverse Chrg. VAT Acc."; Rec."Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reverse Chrg. VAT Unreal. Acc."; Rec."Reverse Chrg. VAT Unreal. Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post amounts for unrealized reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                    Visible = UnrealizedVATVisible;
                }
                field("VAT Charge No."; Rec."VAT Charge No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT charge number associated with the VAT posting setup information.';
                }
            }
            group(Settlement)
            {
                Caption = 'Settlement';
                field("VAT Settlement Template"; Rec."VAT Settlement Template")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT settlement template associated with the VAT posting setup information.';
                }
                field("VAT Settlement Batch"; Rec."VAT Settlement Batch")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the settlement batch associated with the VAT posting setup information.';
                }
                field("Manual VAT Settlement"; Rec."Manual VAT Settlement")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT posting setup information contains a manual VAT settlement.';
                }
                field("Write-Off VAT Account"; Rec."Write-Off VAT Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the write-off VAT account associated with the VAT posting setup information.';
                }
            }
            group(Reinstatement)
            {
                Caption = 'Reinstatement';
                field("VAT Reinstatement Template"; Rec."VAT Reinstatement Template")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT reinstatement template associated with the VAT posting setup information.';
                }
                field("VAT Reinstatement Batch"; Rec."VAT Reinstatement Batch")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT reinstatement batch associated with the VAT posting setup information.';
                }
            }
            group(Usage)
            {
                Caption = 'Usage';
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
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action("Default VAT &Allocation")
                {
                    ApplicationArea = VAT;
                    Caption = 'Default VAT &Allocation';
                    RunObject = Page "Default VAT Allocation";
                    RunPageLink = "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                  "VAT Prod. Posting Group" = field("VAT Prod. Posting Group");
                }
            }
        }
        area(processing)
        {
            action(SuggestAccounts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Suggest Accounts';
                Image = Default;
                ToolTip = 'Suggest G/L Accounts for the selected setup. Suggestions will be based on similar setups and provide a quick setup that you can adjust to your business needs. If no similar setups exists no suggestion will be provided.';

                trigger OnAction()
                begin
                    Rec.SuggestSetupAccounts();
                end;
            }
            action(Copy)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Copy';
                Ellipsis = true;
                Image = Copy;
                ToolTip = 'Copy selected fields or all fields in the VAT Posting Setup window to a new record. Before you start to copy, you must create the new record.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    CopyVATPostingSetup.SetVATSetup(Rec);
                    CopyVATPostingSetup.RunModal();
                    Clear(CopyVATPostingSetup);
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SuggestAccounts_Promoted; SuggestAccounts)
                {
                }
                actionref(Copy_Promoted; Copy)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
    begin
        Rec.SetAccountsVisibility(UnrealizedVATVisible, AdjustForPmtDiscVisible);
        NonDeductibleVATVisible := NonDeductibleVAT.IsNonDeductibleVATEnabled();
    end;

    var
        CopyVATPostingSetup: Report "Copy - VAT Posting Setup";
        UnrealizedVATVisible: Boolean;
        AdjustForPmtDiscVisible: Boolean;
        NonDeductibleVATVisible: Boolean;
}

