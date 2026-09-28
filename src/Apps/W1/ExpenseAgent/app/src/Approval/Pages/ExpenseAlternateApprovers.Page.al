// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7140 "Expense Alternate Approvers"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "Expense Alternate Approver";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Primary Approver No."; Rec."Primary Approver No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the primary approver covered by the alternate.';
                }
                field("Alternate Approver No."; Rec."Alternate Approver No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the approver who acts on behalf of the primary approver.';
                }
                field("Effective Start Date"; Rec."Effective Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date on which the alternate can approve.';
                }
                field("Effective End Date"; Rec."Effective End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the alternate can approve. Leave blank for ongoing coverage.';
                }
            }
        }
    }
}
