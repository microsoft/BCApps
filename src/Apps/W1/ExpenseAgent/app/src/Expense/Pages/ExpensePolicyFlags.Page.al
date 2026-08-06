// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7099 "Expense Policy Flags"
{
    PageType = ListPart;
    SourceTable = "Expense Policy Flag";
    Caption = 'Policy Flags';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
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
                field("Flagged At"; Rec."Flagged At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when this policy flag was created.';
                }
            }
        }
    }
}
