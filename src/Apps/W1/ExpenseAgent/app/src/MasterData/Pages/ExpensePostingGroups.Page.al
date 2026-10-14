// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6976 "Expense Posting Groups"
{
    Caption = 'Expense Posting Groups';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    RefreshOnActivate = true;
    SourceTable = "Expense Posting Group";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the posting group code.';
                }
                field("Prepayment Credit Account"; Rec."Prepayment Credit Account")
                {
                    ToolTip = 'Specifies the prepayment credit account for this posting group.';
                }
                field("Refundable Debit Account"; Rec."Refundable Debit Account")
                {
                    ToolTip = 'Specifies the refund payable account for this posting group.';
                }
                field("Non-Refundable Debit Account"; Rec."Non-Refundable Debit Account")
                {
                    ToolTip = 'Specifies the non-refundable expense account for this posting group.';
                }
                field("Debit Rounding Account"; Rec."Debit Rounding Account")
                {
                    ToolTip = 'Specifies the value of the Expense Debit Rounding Account field.';
                }
                field("Credit Rounding Account"; Rec."Credit Rounding Account")
                {
                    ToolTip = 'Specifies the value of the Expense Credit Rounding Account field.';
                }
            }
        }
    }
}