// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using System.Telemetry;

/// <summary>
/// Card page for configuring General Posting Setup records that define G/L account assignments for business and product posting group combinations.
/// Controls account mappings for sales, purchases, cost of goods sold, inventory adjustments, and manufacturing transactions.
/// </summary>
/// <remarks>
/// Key functionality: G/L account setup for automated posting, VAT integration, show/hide account options.
/// Used extensively in sales, purchase, inventory, and manufacturing posting processes.
/// Critical for ensuring proper G/L account assignments across all business transactions.
/// </remarks>
page 395 "General Posting Setup Card"
{
    Caption = 'General Posting Setup Card';
    DataCaptionFields = "Gen. Bus. Posting Group", "Gen. Prod. Posting Group";
    PageType = Card;
    SourceTable = "General Posting Setup";

    layout
    {
        area(content)
        {
            group(Control11)
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
                            SalesLineDiscVisible := true;
                            SalesInvDiscVisible := true;
                            PurchLineDiscVisible := true;
                            PurchInvDiscVisible := true;
                        end else
                            Rec.SetAccountsVisibility(
                              PmtToleranceVisible, PmtDiscountVisible, SalesInvDiscVisible, SalesLineDiscVisible, PurchInvDiscVisible, PurchLineDiscVisible);

                        CurrPage.Update();
                    end;
                }
            }
            group(General)
            {
                Caption = 'General';
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
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
                field("View All Accounts on Lookup"; Rec."View All Accounts on Lookup")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales Account"; Rec."Sales Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Credit Memo Account"; Rec."Sales Credit Memo Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Line Disc. Account"; Rec."Sales Line Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = SalesLineDiscVisible;
                }
                field("Sales Inv. Disc. Account"; Rec."Sales Inv. Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = SalesInvDiscVisible;
                }
                field("Sales Pmt. Disc. Debit Acc."; Rec."Sales Pmt. Disc. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtDiscountVisible;
                }
                field("Sales Pmt. Disc. Credit Acc."; Rec."Sales Pmt. Disc. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtDiscountVisible;
                }
                field("Sales Pmt. Tol. Debit Acc."; Rec."Sales Pmt. Tol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtToleranceVisible;
                }
                field("Sales Pmt. Tol. Credit Acc."; Rec."Sales Pmt. Tol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtToleranceVisible;
                }
                field("Sales Prepayments Account"; Rec."Sales Prepayments Account")
                {
                    ApplicationArea = Prepayments;
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purch. Account"; Rec."Purch. Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Purch. Credit Memo Account"; Rec."Purch. Credit Memo Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Purch. Line Disc. Account"; Rec."Purch. Line Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PurchLineDiscVisible;
                }
                field("Purch. Inv. Disc. Account"; Rec."Purch. Inv. Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PurchInvDiscVisible;
                }
                field("Purch. Pmt. Disc. Debit Acc."; Rec."Purch. Pmt. Disc. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtDiscountVisible;
                }
                field("Purch. Pmt. Disc. Credit Acc."; Rec."Purch. Pmt. Disc. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtDiscountVisible;
                }
                field("Purch. FA Disc. Account"; Rec."Purch. FA Disc. Account")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies the account that the line and invoice discount will be posted to when the Subtract Disc. in Purch. Inv. field is check marked.';
                }
                field("Purch. Pmt. Tol. Debit Acc."; Rec."Purch. Pmt. Tol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtToleranceVisible;
                }
                field("Purch. Pmt. Tol. Credit Acc."; Rec."Purch. Pmt. Tol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = PmtToleranceVisible;
                }
                field("Purch. Prepayments Account"; Rec."Purch. Prepayments Account")
                {
                    ApplicationArea = Prepayments;
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                field("COGS Account"; Rec."COGS Account")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("COGS Account (Interim)"; Rec."COGS Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the interim G/L account number to which you want the program to post the expected cost of goods sold.';
                }
                field("Inventory Adjmt. Account"; Rec."Inventory Adjmt. Account")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Invt. Accrual Acc. (Interim)"; Rec."Invt. Accrual Acc. (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the G/L account to which you want the program to post expected inventory adjustments (positive and negative).';
                }
                field("Direct Cost Applied Account"; Rec."Direct Cost Applied Account")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    Importance = Additional;
                }
                field("Overhead Applied Account"; Rec."Overhead Applied Account")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    Importance = Additional;
                    ToolTip = 'Specifies the general ledger account number to post the direct cost applied with this particular combination of business posting group and product posting group.';
                }
                field("Purchase Variance Account"; Rec."Purchase Variance Account")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    Importance = Additional;
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
                ToolTip = 'Copy a record with selected fields or all fields from the general posting setup to a new record. Before you start to copy you have to create the new record.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    CopyGenPostingSetup.SetGenPostingSetup(Rec);
                    CopyGenPostingSetup.RunModal();
                    Clear(CopyGenPostingSetup);
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
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        Rec.SetAccountsVisibility(
          PmtToleranceVisible, PmtDiscountVisible, SalesInvDiscVisible, SalesLineDiscVisible, PurchInvDiscVisible, PurchLineDiscVisible);
        FeatureTelemetry.LogUptake('0000KQF', 'Prepayment Sales', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000KQG', 'Prepayment Sales', Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUptake('0000KQH', 'Prepayment Purchase', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000KQI', 'Prepayment Purchase', Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        CopyGenPostingSetup: Report "Copy - General Posting Setup";

    protected var
        PmtDiscountVisible: Boolean;
        PmtToleranceVisible: Boolean;
        SalesLineDiscVisible: Boolean;
        SalesInvDiscVisible: Boolean;
        PurchLineDiscVisible: Boolean;
        PurchInvDiscVisible: Boolean;
        ShowAllAccounts: Boolean;
}

