// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority field are evaluated first. If you are not sure what to configure here then use the three defaults. The document specific lot blocking is for item+variant+lot+serial+package combinations, and can be used for serial-only tracking, or package-only tracking.
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
    AboutText = 'Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority field are evaluated first. If you are not sure what to configure here then use the three defaults. The document specific lot blocking is for item+variant+lot+serial+package combinations, and can be used for serial-only tracking, or package-only tracking.';

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                field(Code; Rec.Code)
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'The short name for the result.';
                }
                field(Description; Rec.Description)
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'A friendly description for the result.';
                }
                field("Evaluation Sequence"; Rec."Evaluation Sequence")
                {
                    AboutTitle = 'About This Field';
                    AboutText = '0 gets evaluated first, 1 would get evaluated after, 2 evaluated after that. 0 is typically used for an incomplete / unfilled state. Lower numbers should be used to evaluate error scenarios where the default of ''notblank''. Higher numbers would typically be used for pass scenarios. ';

                    trigger OnValidate()
                    begin
                        ValidateEvaluationSequenceNotUsedElsewhere();
                    end;
                }
                field("Copy Behavior"; Rec."Copy Behavior")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'Whether to automatically configure this result on new fields and new templates.';
                }
                field("Result Visibility"; Rec."Result Visibility")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'Whether to promote the visibility. Pass conditions are typically promoted. A promoted rule will show on some pages more than others, such as the Certificate of Analysis.';
                }
                field("Result Category"; Rec."Result Category")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'A general categorization of whether this result represents good or bad.';
                }
                field("Finish Allowed"; Rec."Finish Allowed")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'Specifies if an inspection can be finished given the applicable result.';
                }
                field("Default Number Condition"; Rec."Default Number Condition")
                {
                    Visible = false;
                    AboutTitle = 'About This Field';
                    AboutText = 'The numerical related validation, this is the default condition of when this result is activated.';
                }
                field("Default Text Condition"; Rec."Default Text Condition")
                {
                    Visible = false;
                    AboutTitle = 'About This Field';
                    AboutText = 'For text related validation this is the default condition of when this result is activated.';
                }
                field("Default Boolean Condition"; Rec."Default Boolean Condition")
                {
                    Visible = false;
                    AboutTitle = 'About This Field';
                    AboutText = 'For boolean related validation this is the default condition of when this result is activated.';
                }
                field("Lot Allow Sales"; Rec."Lot Allow Sales")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow sales transactions.';
                }
                field("Lot Allow Purchase"; Rec."Lot Allow Purchase")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Purchase transactions.';
                }
                field("Lot Allow Transfer"; Rec."Lot Allow Transfer")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Transfer transactions.';
                }
                field("Lot Allow Consumption"; Rec."Lot Allow Consumption")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Consumption transactions.';
                }
                field("Lot Allow Output"; Rec."Lot Allow Output")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Output transactions.';
                }
                field("Lot Allow Assembly Consumption"; Rec."Lot Allow Assembly Consumption")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Assembly Consumption transactions.';
                }
                field("Lot Allow Assembly Output"; Rec."Lot Allow Assembly Output")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Assembly Output transactions.';
                }
                field("Lot Allow Invt. Movement"; Rec."Lot Allow Invt. Movement")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Inventory Movement transactions.';
                }
                field("Lot Allow Invt. Pick"; Rec."Lot Allow Invt. Pick")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Inventory Pick transactions.';
                }
                field("Lot Allow Invt. Put-Away"; Rec."Lot Allow Invt. Put-Away")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Inventory Put-Away transactions.';
                }
                field("Lot Allow Movement"; Rec."Lot Allow Movement")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Inventory Movement transactions.';
                }
                field("Lot Allow Pick"; Rec."Lot Allow Pick")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Pick transactions.';
                }
                field("Lot Allow Put-Away"; Rec."Lot Allow Put-Away")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'When an inspection for a lot/serial/package has this result this determines whether or not to allow Put-Away transactions.';
                }
                field("Override Style"; Rec."Override Style")
                {
                    AboutTitle = 'About This Field';
                    AboutText = 'Allows you to define a specific style for this result. Leave blank to use defaults.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditResultStyle();
                    end;
                }
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
