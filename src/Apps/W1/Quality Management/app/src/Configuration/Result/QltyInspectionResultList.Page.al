// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority test are evaluated first.
/// </summary>
page 20416 "Qlty. Inspection Result List"
{
    Caption = 'Quality Inspection Results';
    SourceTable = "Qlty. Inspection Result";
    SourceTableView = sorting("Evaluation Sequence");
    PageType = List;
    ApplicationArea = QualityManagement;
    UsageCategory = Lists;
    AboutTitle = 'About Inspection Results';
    AboutText = 'Inspection results show the outcome of an inspection, such as *In progress, Fail*, or *Pass*. You can set up custom grades to match your process.';

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
                    AboutTitle = 'Evaluation Sequence';
                    AboutText = 'The evaluation sequence sets the priority order for checking results. Inspection results with lower numbers are checked first, so *Fail* or *In progress* conditions are usually prioritized before *Pass*.';

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
                    AboutTitle = 'Result Visibility';
                    AboutText = '*Promote* important results, typically pass conditions, so they will show on pages and reports, such as Quality Tests, Quality Inspections and Certificate of Analysis.';
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
                field("Item Tracking Allow Sales"; Rec."Item Tracking Allow Sales")
                {
                    AboutTitle = 'Allow or block specific transactions';
                    AboutText = 'For items with lot, serial, or package tracking, you can specify how quality inspection results affect specific document transactions. For example, you can block purchase documents while inspections are in progress and block sales documents for failed inspections.';
                }
                field("Item Tracking Allow Purchase"; Rec."Item Tracking Allow Purchase")
                {
                }
                field("Item Tracking Allow Transfer"; Rec."Item Tracking Allow Transfer")
                {
                }
                field("Item Tracking Allow Consump."; Rec."Item Tracking Allow Consump.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Item Tracking Allow Output"; Rec."Item Tracking Allow Output")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Item Tracking Allow Asm. Cons."; Rec."Item Tracking Allow Asm. Cons.")
                {
                    ApplicationArea = Assembly;
                }
                field("Item Tracking Allow Asm. Out."; Rec."Item Tracking Allow Asm. Out.")
                {
                    ApplicationArea = Assembly;
                }
                field("Item Tracking Allow Invt. Mov."; Rec."Item Tracking Allow Invt. Mov.")
                {
                }
                field("Item Tracking Allow Invt. Pick"; Rec."Item Tracking Allow Invt. Pick")
                {
                }
                field("Item Tracking Allow Invt. PA"; Rec."Item Tracking Allow Invt. PA")
                {
                }
                field("Item Tracking Allow Movement"; Rec."Item Tracking Allow Movement")
                {
                }
                field("Item Tracking Allow Pick"; Rec."Item Tracking Allow Pick")
                {
                }
                field("Item Tracking Allow Put-Away"; Rec."Item Tracking Allow Put-Away")
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
