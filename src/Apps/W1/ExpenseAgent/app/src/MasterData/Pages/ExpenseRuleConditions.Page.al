// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6902 "Expense Rule Conditions"
{
    Caption = 'Expense Rule Conditions';
    PageType = ListPart;
    SourceTable = "Expense Rule Condition";
    AutoSplitKey = true;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(ConditionsRepeater)
            {
                field("Condition Type"; Rec."Condition Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of rule condition.';
                }
                field("Value"; Rec."Value")
                {
                    AutoFormatType = 0;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum amount for this condition (if applicable).';
                }
            }
        }
    }
}