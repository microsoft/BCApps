// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7127 "Expense Policies"
{
    PageType = List;
    SourceTable = "Expense Policy";
    Caption = 'Expense Policies';
    ApplicationArea = All;
    UsageCategory = Lists;
    DelayedInsert = true;
    AboutTitle = 'About expense policies';
    AboutText = 'Define the policies that AI uses to evaluate expense report lines. Policies can apply to a specific expense category or all categories, and enabled policies must be evaluated before an expense report is submitted.';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category this policy applies to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a short description of the policy.';
                }
                field("Policy Text"; Rec."Policy Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full policy text that the AI evaluates expenses against.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this policy is active for evaluation.';
                }
            }
        }
    }
}
