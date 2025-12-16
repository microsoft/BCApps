// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;

/// <summary>
/// For either a test, template line, or inspection instance this contains a description of the criteria to meet that result. There should be one row per entity per result.
/// </summary>
table 20412 "Qlty. I. Result Condit. Conf."
{
    Caption = 'Quality Inspection Result Condition Configuration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Condition Type"; Enum "Qlty. Result Condition Type")
        {
            Description = 'What this condition configuration applies to.';
            Caption = 'Condition Type';
        }
        field(2; "Target Code"; Code[20])
        {
            Caption = 'Target No.';
            Description = 'When the condition type is a template, then this is the template code should be set. When the condition is an inspection, then this refers to a specific Reinspection.';
            NotBlank = true;
            TableRelation = if ("Condition Type" = const("Template")) "Qlty. Inspection Template Hdr.".Code
            else
            if ("Condition Type" = const(Inspection)) "Qlty. Inspection Header"."No."
            else
            if ("Condition Type" = const(Test)) "Qlty. Test".Code;
        }
        field(3; "Target Reinspection No."; Integer)
        {
            Caption = 'Reinspection No. (inspections)';
            Description = 'Only applicable for Reinspections. Does not apply to test configurations or template configurations.';
            BlankZero = true;
        }
        field(4; "Target Line No."; Integer)
        {
            Caption = 'Target Line No.';
            Description = 'When the condition type is a template, then this is the template line no. When the condition is an inspection, then this refers to a specific inspection line no.';
            NotBlank = true;
            TableRelation = if ("Condition Type" = const("Template")) "Qlty. Inspection Template Line"."Line No." where("Template Code" = field("Target Code"))
            else
            if ("Condition Type" = const(Inspection)) "Qlty. Inspection Line"."Line No." where("Inspection No." = field("Target Code"), "Reinspection No." = field("Target Reinspection No."));
        }
        field(5; "Test Code"; Code[20])
        {
            Caption = 'Test Code';
            Description = 'Which field this result condition refers to.';
            NotBlank = false;
            TableRelation = "Qlty. Test".Code;
        }
        field(6; "Result Code"; Code[20])
        {
            Caption = 'Result Code';
            Description = 'The result this refers to.';
            TableRelation = "Qlty. Inspection Result".Code;
            NotBlank = true;
        }
        field(7; "Result Description"; Text[100])
        {
            Caption = 'Result Description';
            Description = 'The result this refers to.';
            Editable = false;
            NotBlank = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Qlty. Inspection Result".Description where(Code = field("Result Code")));
        }
        field(8; "Condition"; Text[500])
        {
            Caption = 'Condition';
            Description = 'The system condition for this test. For example 1 through 3 would be 1..3, More than 5 would be >5. If a choice A out of A,B,C then A.';

            trigger OnValidate()
            var
                QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
            begin
                if Rec."Condition Type" = Rec."Condition Type"::Test then
                    if Rec.Condition <> xRec.Condition then begin
                        if xRec.Condition = Rec."Condition Description" then
                            Rec."Condition Description" := Rec.Condition;

                        QltyResultConditionMgmt.PromptUpdateTemplatesFromTestsIfApplicable(Rec);
                    end;
            end;
        }
        field(9; "Condition Description"; Text[500])
        {
            Description = 'A human friendly description of the condition for the test.';
            Caption = 'Condition Description';

            trigger OnValidate()
            var
                QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
            begin
                if Rec."Condition Type" = Rec."Condition Type"::Test then
                    if Rec."Condition Description" <> xRec."Condition Description" then
                        QltyResultConditionMgmt.PromptUpdateTemplatesFromTestsIfApplicable(Rec);
            end;
        }
        field(10; "Priority"; Integer)
        {
            Description = 'The priority of the result, this also defines the evaluation order. 0 gets evaluated first, 1 would get evaluated after, 2 evaluated after that. 0 is typically used for an incomplete / unfilled state. Lower numbers should be used to evaluate error scenarios where the default of ''notblank''. Higher numbers would typically be used';
            NotBlank = true;
            Caption = 'Priority';
        }
        field(11; "Result Visibility"; Enum "Qlty. Result Visibility")
        {
            Description = 'Whether to try and make this result more prominent, this can optionally be used on some reports and forms.';
            Caption = 'Result Visibility';
        }
    }

    keys
    {
        key(Key1; "Condition Type", "Target Code", "Target Reinspection No.", "Target Line No.", "Test Code", "Result Code")
        {
            Clustered = true;
        }
        key(SortByPriority; "Condition Type", Priority, "Target Code", "Target Reinspection No.", "Target Line No.")
        {
        }
        key(SortByVisibility; "Condition Type", "Result Visibility", Priority, "Target Code", "Target Reinspection No.", "Target Line No.")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateFromResult();
    end;

    trigger OnModify()
    begin
        UpdateFromResult();
    end;

    local procedure UpdateFromResult()
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
    begin
        QltyInspectionResult.Get("Result Code");
        Rec.Priority := QltyInspectionResult."Evaluation Sequence";
        Rec."Result Visibility" := QltyInspectionResult."Result Visibility";
    end;
}
