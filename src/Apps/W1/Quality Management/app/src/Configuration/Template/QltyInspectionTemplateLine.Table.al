// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.Foundation.UOM;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template.Field;

/// <summary>
/// A template line describes which field should be added to the template, and in what order as well
/// as specific pass criteria.
/// </summary>
table 20403 "Qlty. Inspection Template Line"
{
    Caption = 'Quality Inspection Template Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Template Code"; Code[20])
        {
            Caption = 'Template Code';
            Description = 'A template is a collection of fields which could represent questions or measurements to take.';
            NotBlank = true;
            TableRelation = "Qlty. Inspection Template Hdr.".Code;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line no. of the field in this template.';
        }
        field(3; "Field Code"; Code[20])
        {
            Caption = 'Field Code';
            NotBlank = false;
            TableRelation = "Qlty. Field".Code;
            ToolTip = 'Specifies the Field that is to be tested. Click the field to see a list of Fields.';

            trigger OnValidate()
            var
                QltyField: Record "Qlty. Field";
            begin
                if Rec."Field Code" = '' then
                    Rec.Description := ''
                else
                    if QltyField.Get("Field Code") then begin
                        Rec.Description := QltyField.Description;
                        Rec."Unit of Measure Code" := QltyField."Unit of Measure Code";
                    end;

                EnsureResults(Rec."Field Code" <> xRec."Field Code");
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description that is to be displayed. Contains the value of the description field from the Field template. You can replace the text as needed.';
        }
        field(5; "Field Type"; Enum "Qlty. Field Type")
        {
            CalcFormula = lookup("Qlty. Field"."Field Type" where(Code = field("Field Code")));
            Caption = 'Field Type';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the field type of the Field. The program automatically retrieves the value from the Field Type Field Type field on the Field template.';
        }
        field(7; "Allowable Values"; Text[500])
        {
            CalcFormula = lookup("Qlty. Field"."Allowable Values" where(Code = field("Field Code")));
            Caption = 'Allowable Values';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies an expression for the range of values you can enter or select on the Quality Inspection line. The program automatically retrieves the value from the Allowable Values field on the Field template.';
        }
        field(10; "Copied From Template Code"; Code[20])
        {
            Description = 'Used to track where a template was copied from.';
            Caption = 'Copied From Template Code';
        }
        field(11; "Default Value"; Text[250])
        {
            CalcFormula = lookup("Qlty. Field"."Default Value" where(Code = field("Field Code")));
            Caption = 'Default Value';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies a default value to set on the inspection.';
        }
        field(12; "Expression Formula"; Text[500])
        {
            Caption = 'Expression Formula';
            ToolTip = 'Specifies the formula for the expression content when using expression field types.';

            trigger OnValidate()
            begin
                Rec.CalcFields("Field Type");
                if Rec."Expression Formula" <> '' then begin
                    if not (Rec."Field Type" in [Rec."Field Type"::"Field Type Text Expression"]) then
                        Error(OnlyFieldExpressionErr);

                    ValidateExpressionFormula();
                end;
            end;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure for the measurement.';
            TableRelation = "Unit of Measure".Code;
        }
    }

    keys
    {
        key(Key1; "Template Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Template Code", "Field Code")
        {
        }
    }

    var
        OnlyFieldExpressionErr: Label 'The Expression Formula can only be used with fields that are a type of Expression';

    trigger OnInsert()
    begin
        if Rec.IsTemporary() then
            exit;

        InitLineNoIfNeeded();
        EnsureResults(true);
        Rec.CalcFields("Field Type");
    end;

    procedure InitLineNoIfNeeded()
    var
        ExistingsQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        if Rec."Line No." = 0 then begin
            ExistingsQltyInspectionTemplateLine.SetRange("Template Code", Rec."Template Code");
            ExistingsQltyInspectionTemplateLine.SetCurrentKey("Template Code", "Line No.");
            ExistingsQltyInspectionTemplateLine.Ascending(false);
            if ExistingsQltyInspectionTemplateLine.FindFirst() then;
            Rec."Line No." := ExistingsQltyInspectionTemplateLine."Line No." + 10000;
        end;
    end;

    trigger OnModify()
    begin
        EnsureResults(false);
        Rec.CalcFields("Field Type");
        if Rec."Field Type" in [Rec."Field Type"::"Field Type Text Expression"] then
            ValidateExpressionFormula();
    end;

    /// <summary>
    /// Ensures results exist for this template line.
    /// </summary>
    /// <param name="ForceOverwriteConditions"></param>
    procedure EnsureResults(ForceOverwriteConditions: Boolean)
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.CopyResultConditionsFromFieldToTemplateLine(Rec."Template Code", Rec."Line No.", '', ForceOverwriteConditions);
    end;

    /// <summary>
    /// This will validate the expression formula.
    /// </summary>
    procedure ValidateExpressionFormula()
    var
        Handled: Boolean;
    begin
        Rec.CalcFields("Field Type");

        OnValidateExpressionFormula(Rec, Handled);
        if Handled then
            exit;
    end;

    /// <summary>
    /// Validates the expression formula.
    /// </summary>
    /// <param name="QltyInspectionTemplateLine"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateExpressionFormula(var QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; var Handled: Boolean)
    begin
    end;
}
