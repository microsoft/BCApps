// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;

/// <summary>
/// For either a field, template line, or test instance this contains a description of the criteria to meet that grade.  There should be one row per entity per grade.
/// </summary>
table 20412 "Qlty. I. Grade Condition Conf."
{
    Caption = 'Quality Inspection Grade Condition Configuration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Condition Type"; Enum "Qlty. Grade Condition Type")
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
            if ("Condition Type" = const(Field)) "Qlty. Field".Code;
        }
        field(3; "Target Reinspection No."; Integer)
        {
            Caption = 'Reinspection No. (tests)';
            Description = 'Only applicable for Reinspections. Does not apply to field configurations or template configurations.';
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
        field(5; "Field Code"; Code[20])
        {
            Caption = 'Field Code';
            Description = 'Which field this grade condition refers to.';
            NotBlank = false;
            TableRelation = "Qlty. Field".Code;
        }
        field(6; "Grade Code"; Code[20])
        {
            Caption = 'Grade Code';
            Description = 'The grade this refers to.';
            TableRelation = "Qlty. Inspection Grade".Code;
            NotBlank = true;
        }
        field(7; "Grade Description"; Text[100])
        {
            Caption = 'Grade Description';
            Description = 'The grade this refers to.';
            Editable = false;
            NotBlank = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Qlty. Inspection Grade".Description where(Code = field("Grade Code")));
        }
        field(8; "Condition"; Text[500])
        {
            Caption = 'Condition';
            Description = 'The system condition for this field. For example 1 through 3 would be 1..3, More than 5 would be >5. If a choice A out of A,B,C then A.';

            trigger OnValidate()
            var
                QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
            begin
                if Rec."Condition Type" = Rec."Condition Type"::Field then
                    if Rec.Condition <> xRec.Condition then begin
                        if xRec.Condition = Rec."Condition Description" then
                            Rec."Condition Description" := Rec.Condition;

                        QltyGradeConditionMgmt.PromptUpdateTemplatesFromFieldsIfApplicable(Rec);
                    end;
            end;
        }
        field(9; "Condition Description"; Text[500])
        {
            Description = 'A human friendly description of the condition for the field.';
            Caption = 'Condition Description';

            trigger OnValidate()
            var
                QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
            begin
                if Rec."Condition Type" = Rec."Condition Type"::Field then
                    if Rec."Condition Description" <> xRec."Condition Description" then
                        QltyGradeConditionMgmt.PromptUpdateTemplatesFromFieldsIfApplicable(Rec);
            end;
        }
        field(10; "Priority"; Integer)
        {
            Description = 'The priority of the grade, this also defines the evaluation order. 0 gets evaluated first, 1 would get evaluated after, 2 evaluated after that. 0 is typically used for an incomplete / unfilled state. Lower numbers should be used to evaluate error scenarios where the default of ''notblank''. Higher numbers would typically be used';
            NotBlank = true;
            Caption = 'Priority';
        }
        field(11; "Grade Visibility"; Enum "Qlty. Grade Visibility")
        {
            Description = 'Whether to try and make this grade more prominent, this can optionally be used on some reports and forms.';
            Caption = 'Grade Visibility';
        }
    }

    keys
    {
        key(Key1; "Condition Type", "Target Code", "Target Reinspection No.", "Target Line No.", "Field Code", "Grade Code")
        {
            Clustered = true;
        }
        key(SortByPriority; "Condition Type", Priority, "Target Code", "Target Reinspection No.", "Target Line No.")
        {
        }
        key(SortByVisibility; "Condition Type", "Grade Visibility", Priority, "Target Code", "Target Reinspection No.", "Target Line No.")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateFromGrade();
    end;

    trigger OnModify()
    begin
        UpdateFromGrade();
    end;

    local procedure UpdateFromGrade()
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
    begin
        QltyInspectionGrade.Get("Grade Code");
        Rec.Priority := QltyInspectionGrade."Evaluation Sequence";
        Rec."Grade Visibility" := QltyInspectionGrade."Grade Visibility";
    end;
}
