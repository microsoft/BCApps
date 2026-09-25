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
                    Editable = not SingleCategoryMode;
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

    var
        SingleCategoryMode: Boolean;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        // Updates if filter is changed
        SingleCategoryMode := ExtractCategoryFromFilter() <> '';
        exit(Rec.Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Expense Category Code" := ExtractCategoryFromFilter();
    end;

    local procedure ExtractCategoryFromFilter() ExtractedCategory: Code[20]
    begin
        // According to docs, FilterGroup 4 should contain the filter set by the RunPageLink property,
        // but sometimes these filters end up in filter group 0 instead.
        if TryExtractCategoryFromFilterGroup(ExtractedCategory, 4) then;
        if ExtractedCategory = '' then
            if TryExtractCategoryFromFilterGroup(ExtractedCategory, 0) then;
    end;

    [TryFunction]
    local procedure TryExtractCategoryFromFilterGroup(var ExtractedCategory: Code[20]; FilterGroupToCheck: Integer)
    var
        PrevFilterGroup: Integer;
        CategoryFilter: Text;
    begin
        PrevFilterGroup := Rec.FilterGroup(FilterGroupToCheck);

        CategoryFilter := Rec.GetFilter("Expense Category Code");
        if CategoryFilter <> '' then
            if Rec.GetRangeMin("Expense Category Code") = Rec.GetRangeMax("Expense Category Code") then
                ExtractedCategory := Rec.GetRangeMin("Expense Category Code");

        Rec.FilterGroup(PrevFilterGroup);
    end;
}
