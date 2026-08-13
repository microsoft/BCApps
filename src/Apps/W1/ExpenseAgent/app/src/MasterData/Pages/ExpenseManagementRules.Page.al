// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6900 "Expense Management Rules"
{
    Caption = 'Expense Management Rules';
    PageType = List;
    SourceTable = "Expense Rule Header";
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    CardPageID = "Expense Rule Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ToolTip = 'Specifies the expense category for this rule.';
                }
                field("Expense Location"; Rec."Expense Location")
                {
                    ToolTip = 'Specifies the expense location for this rule.';
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ToolTip = 'Specifies when this rule becomes effective.';
                }
            }
        }
    }
}