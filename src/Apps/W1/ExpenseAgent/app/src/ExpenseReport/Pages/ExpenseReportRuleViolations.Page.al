// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6932 "Expense Report Rule Violations"
{
    PageType = ListPart;
    SourceTable = "Expense Report Rule Violation";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'Violations';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the rule violation.';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}