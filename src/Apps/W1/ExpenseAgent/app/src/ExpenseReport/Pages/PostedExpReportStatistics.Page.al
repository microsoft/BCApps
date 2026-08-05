#if not CLEAN29
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6978 "Posted Exp. Report Statistics"
{
    PageType = CardPart;
    SourceTable = "Posted Expense Report Header";
    Caption = 'Expense Report Statistics';
    ObsoleteReason = 'Replaced by page Posted Expense Report FactBox';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    layout
    {
        area(Content)
        {
            field("Employee Posting Group"; Rec."Employee Posting Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the Employee Posting Group field.';
            }
            field("Reimbursable Amount"; Rec."Reimbursable Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the Reimbursable Amount field.';
            }
            field("Reimbursement Currency Code"; Rec."Reimbursement Currency Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the Reimbursement Currency Code field.';
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the Description field.';
            }
        }
    }
}
#pragma warning restore AL0432
#endif
