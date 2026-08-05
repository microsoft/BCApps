// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6965 "Exp. Rule Conditions Preview"
{
    Caption = 'Rule conditions';
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Rule Condition";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Conditions)
            {
                field("Condition Type"; Rec."Condition Type")
                {
                    ToolTip = 'Specifies the type of the condition.';
                }
                field(Value; Rec.Value)
                {
                    ToolTip = 'Specifies the value against which the condition is evaluated.';
                }
            }
        }
    }

    internal procedure Load(var TempRuleCondition: Record "Expense Rule Condition" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if TempRuleCondition.FindSet() then
            repeat
                Rec := TempRuleCondition;
                Rec.Insert();
            until TempRuleCondition.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}