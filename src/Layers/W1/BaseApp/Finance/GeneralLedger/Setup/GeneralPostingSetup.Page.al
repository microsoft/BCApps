// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

page 314 "General Posting Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'General Posting Setup';
    CardPageID = "General Posting Setup Card";
    DataCaptionFields = "Gen. Bus. Posting Group", "Gen. Prod. Posting Group";
    Editable = true;
    PageType = List;
    AboutTitle = 'About General Posting Setup';
    AboutText = 'Configure how sales, purchases, and inventory transactions are posted to general ledger accounts by defining combinations of general business and product posting groups. Map customers, vendors, items, and resources to the correct accounts to ensure accurate financial reporting.';
    SourceTable = "General Posting Setup";
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
            repeater(Control1)
            {
                FreezeColumn = "Gen. Prod. Posting Group";
                ShowCaption = false;
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the general posting setup.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this particular combination of general business posting group and general product posting group is blocked.';
                }
                field("View All Accounts on Lookup"; Rec."View All Accounts on Lookup")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that all possible accounts are shown when you look up from a field. If the check box is not selected, then only accounts related to the involved account category are shown.';
                }
                field("Sales Account"; Rec."Sales Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the general ledger sales account to which the program will post sales transactions with this particular combination of business group and product group.';
                }
                field("Sales Credit Memo Account"; Rec."Sales Credit Memo Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which the program will post transactions involving sales credit memos for this particular combination of business posting group and product posting group.';
                }
                field("Sales Line Disc. Account"; Rec."Sales Line Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post customer/item and quantity discounts when you post sales transactions with this particular combination of business group and product group.';
                    Visible = SalesLineDiscVisible;
                }
                field("Sales Inv. Disc. Account"; Rec."Sales Inv. Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post sales invoice discount amounts when you post sales transactions for this particular combination of business group and product group. To see the account numbers in the';
                    Visible = SalesInvDiscVisible;
                }
                field("Sales Pmt. Disc. Debit Acc."; Rec."Sales Pmt. Disc. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post granted sales payment discount amounts when you post payments for sales with this particular combination of business group and product group.';
                    Visible = PmtDiscountVisible;
                }
                field("Sales Pmt. Disc. Credit Acc."; Rec."Sales Pmt. Disc. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post reductions in sales payment discount amounts when you post payments for sales with this particular combination of business group and product group.';
                    Visible = PmtDiscountVisible;
                }
                field("Sales Pmt. Tol. Debit Acc."; Rec."Sales Pmt. Tol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account to which you want the program to post payment tolerance for purchases with this combination.';
                    Visible = PmtToleranceVisible;
                }
                field("Sales Pmt. Tol. Credit Acc."; Rec."Sales Pmt. Tol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account to which you want the program to post payment tolerance for purchases with this combination.';
                    Visible = PmtToleranceVisible;
                }
                field("Sales Prepayments Account"; Rec."Sales Prepayments Account")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the number of the general ledger account to post purchase prepayment amounts to.';
                }
                field("Purch. Account"; Rec."Purch. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the general ledger account number to which the program will post purchase transactions with this particular combination of business posting group and product posting group.';
                }
                field("Purch. Credit Memo Account"; Rec."Purch. Credit Memo Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which the program will post transactions involving purchase credit memos for this particular combination of business posting group and product posting group.';
                }
                field("Purch. Line Disc. Account"; Rec."Purch. Line Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post purchase line discount amounts with this particular combination of business group and product group.';
                    Visible = PurchLineDiscVisible;
                }
                field("Purch. Inv. Disc. Account"; Rec."Purch. Inv. Disc. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post purchase invoice discount amounts with this particular combination of business group and product group.';
                    Visible = PurchInvDiscVisible;
                }
                field("Purch. Pmt. Disc. Debit Acc."; Rec."Purch. Pmt. Disc. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post reductions in purchase payment discount amounts when you post payments for purchases with this particular combination of business posting group and product posting group.';
                    Visible = PmtDiscountVisible;
                }
                field("Purch. Pmt. Disc. Credit Acc."; Rec."Purch. Pmt. Disc. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post received purchase payment discount amounts when you post payments for purchases with this particular combination of business posting group and product posting group.';
                    Visible = PmtDiscountVisible;
                }
                field("Purch. Pmt. Tol. Debit Acc."; Rec."Purch. Pmt. Tol. Debit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account to which you want the program to post payment tolerance for purchases with this combination.';
                    Visible = PmtToleranceVisible;
                }
                field("Purch. Pmt. Tol. Credit Acc."; Rec."Purch. Pmt. Tol. Credit Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account to which you want the program to post payment tolerance for purchases with this combination.';
                    Visible = PmtToleranceVisible;
                }
                field("Purch. Prepayments Account"; Rec."Purch. Prepayments Account")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the number of the general ledger account to post purchase prepayment amounts to.';
                }
                field("COGS Account"; Rec."COGS Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the general ledger account number to which to post the cost of goods sold with this particular combination of business group and product group.';
                }
                field("COGS Account (Interim)"; Rec."COGS Account (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the interim G/L account to which you want the program to post the expected cost of goods sold with this combination of business group and product group.';
                }
                field("Inventory Adjmt. Account"; Rec."Inventory Adjmt. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post inventory adjustments with this particular combination of business posting group and product posting group.';
                }
                field("Invt. Accrual Acc. (Interim)"; Rec."Invt. Accrual Acc. (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account to which you want to post expected inventory adjustments (positive and negative).';
                }
                field("Direct Cost Applied Account"; Rec."Direct Cost Applied Account")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the general ledger account number to post the direct cost applied with this particular combination of business posting group and product posting group.';
                }
                field("Direct Cost Non-Inv. App. Acc."; Rec."Direct Cost Non-Inv. App. Acc.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Overhead Applied Account"; Rec."Overhead Applied Account")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the general ledger account number to post the overhead applied with this particular combination of business posting group and product posting group.';
                }
                field("Purchase Variance Account"; Rec."Purchase Variance Account")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the general ledger account number to post the direct cost applied with this particular combination of business posting group and product posting group.';
                }
                field("Purch. FA Disc. Account"; Rec."Purch. FA Disc. Account")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the account the line and invoice discount will be posted to when a check mark is placed in the Subtract Disc. in Purch. Inv. field.';
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
            action("&Copy")
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
                actionref("&Copy_Promoted"; "&Copy")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetAccountsVisibility(
          PmtToleranceVisible, PmtDiscountVisible, SalesInvDiscVisible, SalesLineDiscVisible, PurchInvDiscVisible, PurchLineDiscVisible);
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

