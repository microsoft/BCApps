// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority test are evaluated first. If you are not sure what to configure here then use the three defaults. The document specific lot blocking is for item+variant+lot+serial+package combinations, and can be used for serial-only tracking, or package-only tracking.
/// </summary>
page 20416 "Qlty. Inspection Result List"
{
    Caption = 'Quality Inspection Results';
    SourceTable = "Qlty. Inspection Result";
    SourceTableView = sorting("Evaluation Sequence");
    PageType = List;
    ApplicationArea = QualityManagement;
    UsageCategory = Lists;
    AboutTitle = 'About Results';
    AboutText = 'Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority test are evaluated first. If you are not sure what to configure here then use the three defaults. The document specific lot blocking is for item+variant+lot+serial+package combinations, and can be used for serial-only tracking, or package-only tracking.';

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                field(Code; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Evaluation Sequence"; Rec."Evaluation Sequence")
                {
                    trigger OnValidate()
                    begin
                        ValidateEvaluationSequenceNotUsedElsewhere();
                    end;
                }
                field("Copy Behavior"; Rec."Copy Behavior")
                {
                }
                field("Result Visibility"; Rec."Result Visibility")
                {
                }
                field("Result Category"; Rec."Result Category")
                {
                }
                field("Finish Allowed"; Rec."Finish Allowed")
                {
                }
                field("Default Number Condition"; Rec."Default Number Condition")
                {
                    Visible = false;
                }
                field("Default Text Condition"; Rec."Default Text Condition")
                {
                    Visible = false;
                }
                field("Default Boolean Condition"; Rec."Default Boolean Condition")
                {
                    Visible = false;
                }
                field("Lot Allow Sales"; Rec."Lot Allow Sales")
                {
                }
                field("Lot Allow Purchase"; Rec."Lot Allow Purchase")
                {
                }
                field("Lot Allow Transfer"; Rec."Lot Allow Transfer")
                {
                }
                field("Lot Allow Consumption"; Rec."Lot Allow Consumption")
                {
                }
                field("Lot Allow Output"; Rec."Lot Allow Output")
                {
                }
                field("Lot Allow Assembly Consumption"; Rec."Lot Allow Assembly Consumption")
                {
                }
                field("Lot Allow Assembly Output"; Rec."Lot Allow Assembly Output")
                {
                }
                field("Lot Allow Invt. Movement"; Rec."Lot Allow Invt. Movement")
                {
                }
                field("Lot Allow Invt. Pick"; Rec."Lot Allow Invt. Pick")
                {
                }
                field("Lot Allow Invt. Put-Away"; Rec."Lot Allow Invt. Put-Away")
                {
                }
                field("Lot Allow Movement"; Rec."Lot Allow Movement")
                {
                }
                field("Lot Allow Pick"; Rec."Lot Allow Pick")
                {
                }
                field("Lot Allow Put-Away"; Rec."Lot Allow Put-Away")
                {
                }
                field("Override Style"; Rec."Override Style")
                {
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditResultStyle();
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CopyResultsToAllTemplates)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Copy Results to Existing Templates';
                ToolTip = 'Use this to add newly created results configured to Automatically Copy on to existing tests and existing templates.';
                Image = Copy;
                trigger OnAction()
                var
                    QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
                begin
                    QltyResultConditionMgmt.CopyGradeConditionsFromDefaultToAllTemplates();
                end;
            }
        }
    }

    var
        MustChangePriorityErr: Label 'Evaluation Sequence must be unique, you cannot have two results with the same evaluation sequence. Result [%1/%2] already has the same evaluation sequence.', Comment = '%1=The result code, %2=the result condition';

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        ExistingQltyInspectionResult: Record "Qlty. Inspection Result";
    begin
        ExistingQltyInspectionResult.SetCurrentKey("Evaluation Sequence");
        ExistingQltyInspectionResult.Ascending(false);
        if not ExistingQltyInspectionResult.FindFirst() then
            Rec."Evaluation Sequence" := 0
        else
            Rec."Evaluation Sequence" := ExistingQltyInspectionResult."Evaluation Sequence" + 1;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        ValidateEvaluationSequenceNotUsedElsewhere();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ValidateEvaluationSequenceNotUsedElsewhere();
    end;

    local procedure ValidateEvaluationSequenceNotUsedElsewhere()
    var
        ExistingQltyInspectionResult: Record "Qlty. Inspection Result";
    begin
        ExistingQltyInspectionResult.SetFilter(Code, '<>%1', Rec.Code);
        ExistingQltyInspectionResult.SetRange("Evaluation Sequence", Rec."Evaluation Sequence");
        ExistingQltyInspectionResult.SetLoadFields(Description);
        if ExistingQltyInspectionResult.FindFirst() then
            Error(MustChangePriorityErr, ExistingQltyInspectionResult.Code, ExistingQltyInspectionResult.Description);
    end;
}
