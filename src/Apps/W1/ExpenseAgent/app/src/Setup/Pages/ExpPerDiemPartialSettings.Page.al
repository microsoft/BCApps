// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6994 "Exp. Per Diem Partial Settings"
{
    PageType = StandardDialog;
    Caption = 'Partial day settings';
    SourceTable = "Expense Agent Setup";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    ApplicationArea = Basic, Suite;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(RuleGroup)
            {
                Caption = 'Rule';
                InstructionalText = 'Specifies how per diem for partial days is determined. The rule is set by the per diem calculation method.';

                field("Partial Day Rules"; Rec."Partial Day Rules")
                {
                    Caption = 'Rule';
                    ToolTip = 'Specifies how per diem for partial days is determined. This value is set by the per diem calculation method.';
                    Editable = false;
                    Enabled = PerDiemEnabled;
                }
                field("Min Hours for Partial Per Diem"; Rec."Min Hours for Partial Per Diem")
                {
                    Caption = 'Partial day minimum hours';
                    ToolTip = 'Specifies the minimum number of hours required to qualify for a partial-day per diem.';
                    Enabled = PerDiemEnabled and (Rec."Partial Day Rules" = Rec."Partial Day Rules"::"Based On Eligible Hours");
                }
                field("Percentage For Partial Day"; Rec."Percentage For Partial Day")
                {
                    Caption = 'Partial day percentage';
                    ToolTip = 'Specifies the percentage of the full per diem rate applied to partial days.';
                    Enabled = PerDiemEnabled;
                }
            }
            group(MealReductionGroup)
            {
                Caption = 'Meal reductions';
                InstructionalText = 'Adjust meal-specific reductions applied to the per diem when meals are provided.';

                field("Reduction for Breakfast %"; Rec."Reduction for Breakfast %")
                {
                    Caption = 'Breakfast reduction (%)';
                    ToolTip = 'Specifies the percentage deducted from the per diem when breakfast is provided.';
                    Enabled = PerDiemEnabled;
                }
                field("Reduction for Lunch %"; Rec."Reduction for Lunch %")
                {
                    Caption = 'Lunch reduction (%)';
                    ToolTip = 'Specifies the percentage deducted from the per diem when lunch is provided.';
                    Enabled = PerDiemEnabled;
                }
                field("Reduction for Dinner %"; Rec."Reduction for Dinner %")
                {
                    Caption = 'Dinner reduction (%)';
                    ToolTip = 'Specifies the percentage deducted from the per diem when dinner is provided.';
                    Enabled = PerDiemEnabled;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then
            PerDiemEnabled := Rec."Full Per-Diem Calculation" <> Rec."Full Per-Diem Calculation"::None;
    end;

    internal procedure Set(var SourceExpenseAgentSetup: Record "Expense Agent Setup")
    begin
        Rec.DeleteAll();
        Rec := SourceExpenseAgentSetup;
        Rec.Insert();
    end;

    internal procedure Get(var TargetExpenseAgentSetup: Record "Expense Agent Setup")
    begin
        if not Rec.FindFirst() then
            exit;

        TargetExpenseAgentSetup."Partial Day Rules" := Rec."Partial Day Rules";
        TargetExpenseAgentSetup."Min Hours for Partial Per Diem" := Rec."Min Hours for Partial Per Diem";
        TargetExpenseAgentSetup."Percentage For Partial Day" := Rec."Percentage For Partial Day";
        TargetExpenseAgentSetup."Reduction for Breakfast %" := Rec."Reduction for Breakfast %";
        TargetExpenseAgentSetup."Reduction for Lunch %" := Rec."Reduction for Lunch %";
        TargetExpenseAgentSetup."Reduction for Dinner %" := Rec."Reduction for Dinner %";
    end;

    var
        PerDiemEnabled: Boolean;
}
