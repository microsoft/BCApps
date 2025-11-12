// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

page 792 "Uncategorized G/L Accounts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Uncategorized G/L Accounts';
    CardPageId = "G/L Account Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "G/L Account";
    SourceTableView = where("Account Category" = const(" "));
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                }
                field(Name; Rec.Name)
                {
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                }
                field("Account Category"; Rec."Account Category")
                {
                }
                field("Account Type"; Rec."Account Type")
                {
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    Visible = false;
                }
                field("Direct Posting"; Rec."Direct Posting")
                {
                }
                field("Reconciliation Account"; Rec."Reconciliation Account")
                {
                }
                field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                {
                }
            }
        }
    }
}