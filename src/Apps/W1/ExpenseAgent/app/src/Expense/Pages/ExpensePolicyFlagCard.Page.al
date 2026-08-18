// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7125 "Expense Policy Flag Card"
{
    PageType = Card;
    SourceTable = "Expense Policy Flag";
    Caption = 'Policy Flag Details';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Subject Type"; Rec."Subject Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of record this policy flag belongs to.';
                }
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category the flagged policy applies to.';
                }
                field("Flagged At"; Rec."Flagged At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when this policy flag was created.';
                }
            }
            group(Policy)
            {
                Caption = 'Policy';

                field("Policy Text"; Rec."Policy Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the policy text that the AI evaluated, captured when the flag was created. It is preserved even if the policy changes later.';
                    MultiLine = true;
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason this policy was flagged for the expense.';
                    MultiLine = true;
                }
            }
        }
    }
}
