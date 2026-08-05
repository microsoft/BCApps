// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6990 "Expense Teams"
{
    Caption = 'Expense Teams';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Expense Team";
    AdditionalSearchTerms = 'Teams, Expense Units, Approval Groups';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the team code.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the team description.';
                }
                field("Number Of Team Members"; Rec."Number Of Team Members")
                {
                    ToolTip = 'Specifies the number of team members.';
                }
            }
        }
    }
}