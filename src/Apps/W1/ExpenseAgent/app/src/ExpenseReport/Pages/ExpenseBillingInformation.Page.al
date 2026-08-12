// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6961 "Expense Billing Information"
{
    PageType = CardPart;
    SourceTable = "Expense Report Line";
    Caption = 'Billing Information';
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group("General")
            {
                Caption = 'General';
                field(Billable; Rec.Billable)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense is billable.';
                }
                field("Billable to Customer"; Rec."Billable to Customer")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer to which the expense is billable.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account to which the expense is billed.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number to which the expense is billed.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor number to which the expense is billed.';
                }
                field("Purchase Invoice"; Rec."Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense is billed through a purchase invoice.';
                }
                field("Posted Purch. Invoice No."; Rec."Posted Purch. Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted purchase invoice for the expense.';
                }
                field("Posted Date"; Rec."Posted Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the expense was posted.';
                }
                field("Expense Ext. Doc. No."; Rec."Expense Ext. Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Receipt No. field.';
                    Caption = 'Receipt No.';
                }
                field("Merchant Name"; Rec."Merchant Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the merchant name associated with the expense report.';
                }
                field("Merchant Registration No."; Rec."Merchant Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company registration number of the merchant.';
                }
                field("Merchant VAT Registration No."; Rec."Merchant VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number of the merchant.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Project No. field.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Project Task No. field.';
                }
            }
        }
    }
}