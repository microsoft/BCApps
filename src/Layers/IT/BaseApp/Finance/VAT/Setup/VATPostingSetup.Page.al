// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Reporting;

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
                field("Include in VAT Transac. Rep."; Rec."Include in VAT Transac. Rep.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you want to include the entry in the VAT transaction report.';
                }
                field("Deductible %"; Rec."Deductible %")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the percentage of the transaction amount to which VAT is applied.';
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
                field("Service Tariff No. Mandatory"; Rec."Service Tariff No. Mandatory")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the service tariff number is required for tax reporting.';
                }
                field("Nondeductible VAT Account"; Rec."Nondeductible VAT Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the account associated with the VAT amount that is not deducted due to the type of goods or services purchased.';
                }
                field("Allow Posting From"; Rec."Allow Posting From")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the start date from which VAT posting is allowed.';
                }
                field("Allow Posting To"; Rec."Allow Posting To")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the end date to which VAT posting is allowed.';
                }
                field("Sales Prepayments Account"; Rec."Sales Prepayments Account")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the account to which you want to post the VAT sales prepayment amount.';
                    Visible = false;
                }
                field("Purch. Prepayments Account"; Rec."Purch. Prepayments Account")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the account to which you want to post the VAT purchases prepayment amount.';
                    Visible = false;
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
                field("Reversed VAT Bus. Post. Group"; Rec."Reversed VAT Bus. Post. Group")
                {
                    ApplicationArea = VAT;
                    Editable = Rec."VAT Calculation Type" = Rec."VAT Calculation Type"::"Full VAT";
                    ToolTip = 'Specifies the business posting group for reversed VAT.';
                }
                field("Reversed VAT Prod. Post. Group"; Rec."Reversed VAT Prod. Post. Group")
                {
                    ApplicationArea = VAT;
                    Editable = Rec."VAT Calculation Type" = Rec."VAT Calculation Type"::"Full VAT";
                    ToolTip = 'Specifies the product posting group for reversed VAT.';
                }
                field("VAT Transaction Nature"; Rec."VAT Transaction Nature")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the nature of the VAT transaction.';
                }
                field("Include in VAT Comm. Rep."; Rec."Include in VAT Comm. Rep.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you want to include the entry in the VAT Payment Communication report.';
                }
                field("Fattura Document Type"; Rec."Fattura Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value to export into the TipoDocument XML node of the Fattura document.';
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
                action("VAT &Transaction Report Amount")
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT &Transaction Report Amount';
                    Image = VATPostingSetup;
                    RunObject = Page "VAT Transaction Report Amounts";
                    ToolTip = 'View or edit the threshold amounts for the VAT transactions report.';
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

