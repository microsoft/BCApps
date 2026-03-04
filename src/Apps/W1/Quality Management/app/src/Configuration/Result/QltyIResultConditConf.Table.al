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
            Caption = 'Condition Type';
            ToolTip = 'Specifies what this condition configuration applies to.';
        }
        field(2; "Target Code"; Code[20])
        {
            Caption = 'Target No.';
            ToolTip = 'Specifies the target code. When the condition type is a template, this is the template code. When the condition is an inspection, this refers to a specific re-inspection.';
            NotBlank = true;
            TableRelation = if ("Condition Type" = const("Template")) "Qlty. Inspection Template Hdr.".Code
            else
            if ("Condition Type" = const(Inspection)) "Qlty. Inspection Header"."No."
            else
            if ("Condition Type" = const(Test)) "Qlty. Test".Code;
        }
        field(3; "Target Re-inspection No."; Integer)
        {
            Caption = 'Re-inspection No. (inspections)';
            ToolTip = 'Specifies the re-inspection number. This is only applicable for re-inspections and does not apply to test configurations or template configurations.';
            BlankZero = true;
        }
        field(4; "Target Line No."; Integer)
        {
            Caption = 'Target Line No.';
            ToolTip = 'Specifies the target line number. When the condition type is a template, this is the template line number. When the condition is an inspection, this refers to a specific inspection line number.';
            NotBlank = true;
            TableRelation = if ("Condition Type" = const("Template")) "Qlty. Inspection Template Line"."Line No." where("Template Code" = field("Target Code"))
            else
            if ("Condition Type" = const(Inspection)) "Qlty. Inspection Line"."Line No." where("Inspection No." = field("Target Code"), "Re-inspection No." = field("Target Re-inspection No."));
        }
        field(5; "Test Code"; Code[20])
        {
            Caption = 'Test Code';
            ToolTip = 'Specifies which field this result condition refers to.';
            NotBlank = false;
            TableRelation = "Qlty. Test".Code;
        }
        field(6; "Result Code"; Code[20])
        {
            Caption = 'Result Code';
            ToolTip = 'Specifies the result this refers to.';
            TableRelation = "Qlty. Inspection Result".Code;
            NotBlank = true;
        }
        field(7; "Result Description"; Text[100])
        {
            Caption = 'Result Description';
            ToolTip = 'Specifies the description of the result this refers to.';
            Editable = false;
            NotBlank = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Qlty. Inspection Result".Description where(Code = field("Result Code")));
        }
        field(8; "Condition"; Text[500])
        {
            Caption = 'Condition';
            ToolTip = 'Specifies the system condition for this test. For example 1 through 3 would be 1..3, More than 5 would be >5. If a choice A out of A,B,C then A.';

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
            Caption = 'Condition Description';
            ToolTip = 'Specifies a human friendly description of the condition for the test.';

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
            Caption = 'Priority';
            ToolTip = 'Specifies the priority of the result, which also defines the evaluation order. Lower numbers are evaluated first (0, then 1, then 2, and so on). Lower numbers are typically used for incomplete states or error scenarios.';
            NotBlank = true;
        }
        field(11; "Result Visibility"; Enum "Qlty. Result Visibility")
        {
            Caption = 'Result Visibility';
            ToolTip = 'Specifies whether to make this result more prominent. This can optionally be used on some reports and forms.';
        }
    }

    keys
    {
        key(Key1; "Condition Type", "Target Code", "Target Re-inspection No.", "Target Line No.", "Test Code", "Result Code")
        {
            Clustered = true;
        }
        key(SortByPriority; "Condition Type", Priority, "Target Code", "Target Re-inspection No.", "Target Line No.")
        {
        }
        key(SortByVisibility; "Condition Type", "Result Visibility", Priority, "Target Code", "Target Re-inspection No.", "Target Line No.")
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
