// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7123 "Expense Policy Flags"
{
    PageType = List;
    SourceTable = "Expense Policy Flag";
    Caption = 'Evaluated Policies';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    CardPageId = "Expense Policy Flag Card";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Compliant; Rec.Compliant)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense complied with this policy when it was evaluated. When cleared, the policy was flagged.';
                }
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category the evaluated policy applies to.';
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reason Flagged';
                    ToolTip = 'Specifies the reason this policy was flagged for the expense. Choose the value to see the full flag details.';
                    StyleExpr = 'Ambiguous';

                    trigger OnDrillDown()
                    var
                        ExpensePolicyFlagCard: Page "Expense Policy Flag Card";
                    begin
                        ExpensePolicyFlagCard.SetRecord(Rec);
                        ExpensePolicyFlagCard.RunModal();
                    end;
                }
                field("Policy Text"; Rec."Policy Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the policy text that the AI evaluated, captured when the flag was created.';
                }
                field("Flagged At"; Rec."Flagged At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when this policy flag was created.';
                }
            }
        }
    }
}
