#if not CLEAN29
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6982 "Expense Report Statistics"
{
    PageType = CardPart;
    SourceTable = "Expense Report Header";
    Caption = 'Expense Report Statistics';
    ObsoleteReason = 'Replaced by page Expense Report FactBox';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    layout
    {
        area(Content)
        {
            field("Employee Posting Group"; Rec."Employee Posting Group")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Reimbursable Amount"; Rec."Reimbursable Amount")
            {
                ApplicationArea = Basic, Suite;
                DrillDown = false;
            }
            field("Reimbursement Currency Code"; Rec."Reimbursement Currency Code")
            {
                ApplicationArea = Basic, Suite;
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
#pragma warning restore AL0432
#endif
