// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Calculation;

/// <summary>
/// VAT posting setup list page displaying all combinations of VAT business and product posting groups with their configuration.
/// Provides overview and management interface for VAT calculation rules, account assignments, and non-deductible VAT settings.
/// </summary>
/// <remarks>
/// Key functionality: Browse and filter VAT posting setups, access individual setup cards, view VAT rates and account assignments.
/// Data source: VAT Posting Setup table with combinations of business and product posting groups.
/// User workflow: Navigate from overview to detailed setup cards for specific posting group combinations.
/// </remarks>
page 472 "VAT Posting Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Posting Setup';
    CardPageID = "VAT Posting Setup Card";
    DataCaptionFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
    Editable = true;
    PageType = List;
    AboutTitle = 'About VAT Posting Setup';
    AboutText = 'Configure how VAT is calculated and posted for different combinations of business and product groups, including VAT rates, calculation types, non-deductible VAT, and related general ledger accounts for sales and purchases.';
    SourceTable = "VAT Posting Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Identifier"; Rec."VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Width = 1;
                }
                field("Allow Non-Deductible VAT"; Rec."Allow Non-Deductible VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = NonDeductibleVATVisible;
                }
                field("Non-Deductible VAT% "; Rec."Non-Deductible VAT %")
                {
                    ApplicationArea = VAT;
                    Width = 1;
                    Visible = NonDeductibleVATVisible;
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unrealized VAT Type"; Rec."Unrealized VAT Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UnrealizedVATVisible;
                }
                field("Adjust for Payment Discount"; Rec."Adjust for Payment Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AdjustForPmtDiscVisible;
                }
                field("Sales VAT Account"; Rec."Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Width = 1;
                }
                field("Sales VAT Unreal. Account"; Rec."Sales VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to post unrealized sales VAT to.';
                    Visible = UnrealizedVATVisible;
                    Width = 1;
                }
                field("Purchase VAT Account"; Rec."Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Width = 1;
                }
                field("Purch. VAT Unreal. Account"; Rec."Purch. VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to post unrealized purchase VAT to.';
                    Visible = UnrealizedVATVisible;
                    Width = 1;
                }
                field("Non-Ded. Purchase VAT Account"; Rec."Non-Ded. Purchase VAT Account")
                {
                    ApplicationArea = VAT;
                    Visible = NonDeductibleVATVisible;
                }
                field("Reverse Chrg. VAT Acc."; Rec."Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Width = 1;
                }
                field("Reverse Chrg. VAT Unreal. Acc."; Rec."Reverse Chrg. VAT Unreal. Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UnrealizedVATVisible;
                    Width = 1;
                }
                field("VAT Clause Code"; Rec."VAT Clause Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Invoice Amount Type"; Rec."Tax Invoice Amount Type")
                {
                    ToolTip = 'Specifies the tax invoice amount type of the VAT posting setup information.';
                    Visible = false;
                }
                field("Not Include into VAT Ledger"; Rec."Not Include into VAT Ledger")
                {
                    ToolTip = 'Specifies if entries that use this posting setup must be excluded from the VAT ledgers for purchases and sales.';
                    Visible = false;
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
                field("Manual VAT Settlement"; Rec."Manual VAT Settlement")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT posting setup information contains a manual VAT settlement.';
                }
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
                field("Write-Off VAT Account"; Rec."Write-Off VAT Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the write-off VAT account associated with the VAT posting setup information.';
                }
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
                field("VAT Charge No."; Rec."VAT Charge No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT charge number associated with the VAT posting setup information.';
                }
                field("VAT Exempt"; Rec."VAT Exempt")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if entries that use this posting setup are VAT exempt.';
                }
                field("Certificate of Supply Required"; Rec."Certificate of Supply Required")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Tax Category"; Rec."Tax Category")
                {
                    ApplicationArea = Basic, Suite;
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
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action("Default VAT &Allocation")
                {
                    ApplicationArea = VAT;
                    Caption = 'Default VAT &Allocation';
                    Image = Allocations;
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

