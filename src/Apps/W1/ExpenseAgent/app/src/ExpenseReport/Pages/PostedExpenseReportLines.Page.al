// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6953 "Posted Expense Report Lines"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Posted Expense Report Line";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Account Type"; Rec."Account Type")
                {
                    ToolTip = 'Specifies the type of account for this line, such as G/L, Customer, or Vendor.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ToolTip = 'Specifies the account number used for posting this line.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the expense line.';
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ToolTip = 'Specifies the category that classifies this expense.';
                }
                field("Expense Location"; Rec."Expense Location")
                {
                    ToolTip = 'Specifies the location where the expense occurred.';
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ToolTip = 'Specifies the date the expense was incurred.';
                }
                field("Posted Date"; Rec."Posted Date")
                {
                    ToolTip = 'Specifies the date this line was posted to the ledger.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the VAT business posting group used for tax calculation.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the VAT product posting group used for tax calculation.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the line amount in the transaction currency.';
                }
                field("Currency Code"; Rec."Expense Currency Code")
                {
                    ToolTip = 'Specifies the currency code for this line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies the unit of measure for the line quantity, if applicable.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ToolTip = 'Specifies the line amount converted to local currency.';
                }
                field("Non-Refundable Amount"; Rec."Non-Refundable Amount")
                {
                    ToolTip = 'Specifies any reduction applied to the line amount.';
                }
                field("Non-Refundable Amount (LCY)"; Rec."Non-Refundable Amount (LCY)")
                {
                    ToolTip = 'Specifies any reduction converted to local currency.';
                }
                field("Reimbursable Amount"; Rec."Reimbursable Amount")
                {
                    ToolTip = 'Specifies the portion of the line amount eligible for reimbursement.';
                }
                field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ToolTip = 'Specifies the reimbursable portion converted to local currency.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ToolTip = 'Specifies the VAT amount for this line in the transaction currency.';
                    Visible = false;
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                    ToolTip = 'Specifies the VAT amount converted to local currency.';
                    Visible = false;
                }
                field("Amount without VAT"; Rec."Amount without VAT")
                {
                    ToolTip = 'Specifies the line amount excluding VAT.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the first shortcut dimension code for this line.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the second shortcut dimension code for this line.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Show Document")
            {
                ApplicationArea = Basic, Suite;
                Image = DocumentEdit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'View the expense report document that contains this line';
                RunObject = page "Expense Report";
                RunPageLink = "No." = field("Document No.");
            }
        }
        area(Navigation)
        {
            action("Participants")
            {
                Image = PersonInCharge;
                Caption = 'Participants';
                ToolTip = 'View and manage participants for this expense report line';
                RunObject = page "Posted Exp. Rep. Line Particip";
                RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
            action("Itemizations")
            {
                Image = ItemGroup;
                Caption = 'Itemizations';
                ToolTip = 'View and manage itemizations for this expense report line';
                RunObject = page "Posted Exp. Rep. Line Items";
                RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
            action("PerDiem")
            {
                Image = CalculateCost;
                Caption = 'Per Diem';
                ToolTip = 'View and manage per diem entries for this expense report line';
                RunObject = page "Posted Exp. Rep. Line Per Diem";
                RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
        }
    }
}