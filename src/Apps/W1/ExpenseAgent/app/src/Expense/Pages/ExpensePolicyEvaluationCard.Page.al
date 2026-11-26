// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7125 "Expense Policy Evaluation Card"
{
    PageType = Card;
    SourceTable = "Expense Policy Evaluation";
    Caption = 'Policy Evaluation Details';
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
                    ToolTip = 'Specifies the type of record this policy evaluation belongs to.';
                }
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category the evaluated policy applies to.';
                }
                field("Evaluated At"; Rec."Evaluated At")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Evaluated At';
                    ToolTip = 'Specifies when the policy was evaluated.';
                }
            }
            group(Policy)
            {
                Caption = 'Policy';

                field("Policy Text"; Rec."Policy Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the policy text that the AI evaluated. It is preserved even if the policy changes later.';
                    MultiLine = true;
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason for the policy evaluation result.';
                    MultiLine = true;
                }
            }
        }
    }
}
