// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7124 "Expense Policy Evaluations"
{
    PageType = List;
    SourceTable = "Expense Policy Evaluation";
    SourceTableView = sorting("Evaluated At") order(descending);
    Caption = 'Evaluated Policies';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    CardPageId = "Expense Policy Evaluation Card";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Compliant; Rec.Compliant)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense complied with this policy when it was evaluated.';
                }
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category the evaluated policy applies to.';
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reason';
                    ToolTip = 'Specifies the reason for the policy evaluation result. Choose the value to see the full details.';
                    StyleExpr = ReasonStyleExpr;

                    trigger OnDrillDown()
                    var
                        ExpensePolicyEvaluationCard: Page "Expense Policy Evaluation Card";
                    begin
                        ExpensePolicyEvaluationCard.SetRecord(Rec);
                        ExpensePolicyEvaluationCard.RunModal();
                    end;
                }
                field("Policy Text"; Rec."Policy Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the policy text that the AI evaluated.';
                }
                field("Evaluated At"; Rec."Evaluated At")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Evaluated At';
                    ToolTip = 'Specifies when the policy was evaluated.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // Only a non-compliant result carries an unfavorable meaning; compliant rows keep
        // the default style so the colour is not mismatched to the reason text.
        if Rec.Compliant then
            ReasonStyleExpr := ''
        else
            ReasonStyleExpr := 'Unfavorable';
    end;

    var
        ReasonStyleExpr: Text;
}
