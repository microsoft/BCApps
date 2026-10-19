// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7097 "Posted Expense Report Stats"
{
    Caption = 'Posted Expense Report Statistics';
    DeleteAllowed = false;

    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    SourceTable = "Posted Expense Report Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total amount of all expense report lines in local currency.';
                }
                field("Amount without VAT (LCY)"; Rec."Amount without VAT (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount without VAT (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total amount excluding VAT of all expense report lines in local currency.';
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount for the expense report in local currency.';
                }
                field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reimbursable Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total reimbursable amount in local currency.';
                }
                field("Refundable Amount (LCY)"; Rec."Refundable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Refundable Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total refundable amount in local currency.';
                }
                field("Approved Reclaim VAT (LCY)"; Rec."Approved Reclaim VAT (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approved Reclaim VAT (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount approved for reclaim in local currency.';
                }
            }
            part(VATSpecification; "Posted Expense Report VAT Spec")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Specification';
                SubPageLink = "Expense Report No." = field("No.");
            }
        }
    }
}