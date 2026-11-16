// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6911 "Expense Report Lines"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Report Line";
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
                    ToolTip = 'Specifies the type of account used for billing this expense.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ToolTip = 'Specifies the account number used for billing this expense.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a brief description of the expense line.';
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ToolTip = 'Specifies the expense category. Category determines required details such as per diem or mileage.';
                }
                field("Expense Location"; Rec."Expense Location")
                {
                    ToolTip = 'Specifies where the expense occurred. Used for reporting and per diem calculations.';
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ToolTip = 'Specifies the date when the expense was incurred.';
                }
                field("Posted Date"; Rec."Posted Date")
                {
                    ToolTip = 'Specifies the date when the line was posted.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the VAT business posting group used when posting VAT for this expense.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the VAT product posting group used when posting VAT for this expense.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the expense amount. Changing the amount recalculates totals.';
                }
                field("Expense Currency Code"; Rec."Expense Currency Code")
                {
                    ToolTip = 'Specifies the currency code used for this expense. The currency determines how the amount is calculated and displayed.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies the unit of measure for the expense amount, for example units or hours.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ToolTip = 'Specifies the expense amount converted to local currency.';
                }
                field("Non-Refundable Amount"; Rec."Non-Refundable Amount")
                {
                    ToolTip = 'Specifies any reduction applied to the amount, for example discounts or contributions.';
                }
                field("Non-Refundable Amount (LCY)"; Rec."Non-Refundable Amount (LCY)")
                {
                    ToolTip = 'Specifies any amount reduction in local currency.';
                }
                field("Reimbursable Amount"; Rec."Reimbursable Amount")
                {
                    ToolTip = 'Specifies the portion of the expense that will be reimbursed to the employee.';
                }
                field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ToolTip = 'Specifies the reimbursable amount in local currency.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ToolTip = 'Specifies the VAT amount for this line. Enter only when VAT is applicable.';
                    Visible = false;
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                    ToolTip = 'Specifies the VAT amount in local currency.';
                    Visible = false;
                }
                field("Amount without VAT"; Rec."Amount without VAT")
                {
                    ToolTip = 'Specifies the amount excluding VAT for this line.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies dimension 1 used for analytics and posting.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies dimension 2 used for analytics and posting.';
                }
            }
        }
        area(FactBoxes)
        {
            part(VATSpecFactBox; "Expense Report Line VATFactBox")
            {
                Caption = 'VAT Specification';
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("Document No."), "Document Line No." = field("Line No.");
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
                ToolTip = 'View the expense report that contains this line.';
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
                RunObject = page "Expense Report Line Particips";
                RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
            action("VAT Specification")
            {
                Image = VATPostingSetup;
                Caption = 'VAT Specification';
                ToolTip = 'View and approve the per-rate VAT breakdown for this expense report line.';
                RunObject = Page "Expense Report Line VAT Spec.";
                RunPageLink = "Document No." = field("Document No."), "Document Line No." = field("Line No.");
                ApplicationArea = Basic, Suite;
                Visible = AllowVATReclaim;
            }
            action("Itemizations")
            {
                Image = ItemGroup;
                Caption = 'Itemizations';
                ToolTip = 'View and manage itemizations for this expense report line';
                RunObject = page "Expense Report Line Items";
                RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
            action("PerDiem")
            {
                Image = CalculateCost;
                Caption = 'Per Diem';
                ToolTip = 'View and manage per diem entries for this expense report line';
                RunObject = page "Expense Report Line Per Diems";
                RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                ApplicationArea = Basic, Suite;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ExpenseAgentSetup.GetRecordOnce();
        AllowVATReclaim := ExpenseAgentSetup."Allow VAT Reclaim";
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        AllowVATReclaim: Boolean;
}