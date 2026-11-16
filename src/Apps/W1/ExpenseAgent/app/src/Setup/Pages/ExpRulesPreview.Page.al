// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6959 "Exp. Rules Preview"
{
    Caption = 'Expense management rules';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Rule Header";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;
    Extensible = false;
    InstructionalText = 'Lists existing expense management rules together with the defaults that will be created when you apply the setup. Select a rule to see its conditions.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense Category Code"; Rec."Expense Category Code")
                {
                    ToolTip = 'Specifies the expense category to which the rule applies.';
                    StyleExpr = StyleExpr;
                }
                field("Expense Location"; Rec."Expense Location")
                {
                    ToolTip = 'Specifies the expense location to which the rule applies.';
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ToolTip = 'Specifies the date from which the rule is effective.';
                }
                field("Justification Required"; Rec."Justification Required")
                {
                    ToolTip = 'Specifies whether justification is required for expenses that match this rule.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency for monetary values in the rule.';
                }
                field(Status; StatusText)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the row is a new default that will be added or already exists.';
                    StyleExpr = StyleExpr;
                }
            }
            part(Conditions; "Exp. Rule Conditions Preview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Conditions';
                SubPageLink = "Expense Category Code" = field("Expense Category Code"),
                              "Expense Location" = field("Expense Location"),
                              "Effective Date" = field("Effective Date");
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReloadPreview();
    end;

    trigger OnAfterGetRecord()
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
    begin
        if ExpenseRuleHeader.Get(Rec."Expense Category Code", Rec."Expense Location", Rec."Effective Date") then begin
            StatusText := ExistingLbl;
            StyleExpr := '';
        end else begin
            StatusText := NewLbl;
            StyleExpr := 'Favorable';
        end;
    end;

    local procedure ReloadPreview()
    var
        TempRuleHeader: Record "Expense Rule Header" temporary;
        TempRuleCondition: Record "Expense Rule Condition" temporary;
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.LoadRulesPreview(TempRuleHeader, TempRuleCondition);

        Rec.Reset();
        Rec.DeleteAll();

        if TempRuleHeader.FindSet() then
            repeat
                Rec := TempRuleHeader;
                Rec.Insert();
            until TempRuleHeader.Next() = 0;

        if Rec.FindFirst() then;

        CurrPage.Conditions.Page.Load(TempRuleCondition);
    end;

    var
        StatusText: Text;
        StyleExpr: Text;
        NewLbl: Label 'New';
        ExistingLbl: Label 'Existing';
}