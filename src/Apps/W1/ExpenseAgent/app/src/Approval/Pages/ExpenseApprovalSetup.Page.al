// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6939 "Expense Approval Setup"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "Expense Approval Setup";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the expense user for expense approval setup.';
                }
                field(ExpenseUserName; Rec."Expense User Name")
                {
                    Editable = false;
                }
                field("Entra Id"; Rec."Entra Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Entra Id for expense approval setup.';
                    Visible = false;
                }
                field("Approver No."; Rec."Approver No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the approver for expense approval setup.';
                }
                field(ApproverName; Rec."Approver Name")
                {
                    Editable = false;
                }
            }
        }
    }
}