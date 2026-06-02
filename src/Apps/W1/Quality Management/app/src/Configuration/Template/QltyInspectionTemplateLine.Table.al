// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.Foundation.UOM;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
/// A template line describes which test should be added to the template, and in what order as well
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
            ToolTip = 'Specifies the template, which is a collection of tests that could represent questions or measurements to take.';
            NotBlank = true;
            TableRelation = "Qlty. Inspection Template Hdr.".Code;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line no. of the test in this template.';
        }
        field(3; "Test Code"; Code[20])
        {
            Caption = 'Test Code';
            NotBlank = false;
            TableRelation = "Qlty. Test".Code;
            ToolTip = 'Specifies the Test that is to be tested. Click the field to see a list of Tests.';

            trigger OnValidate()
            var
                QltyTest: Record "Qlty. Test";
            begin
                if Rec."Test Code" = '' then
                    Rec.Description := ''
                else
                    if QltyTest.Get("Test Code") then begin
                        Rec.Description := QltyTest.Description;
                        Rec."Unit of Measure Code" := QltyTest."Unit of Measure Code";
                    end;

                EnsureResultsExist(Rec."Test Code" <> xRec."Test Code");
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description that is to be displayed. Contains the value of the description field from the Test template. You can replace the text as needed.';
        }
        field(5; "Test Value Type"; Enum "Qlty. Test Value Type")
        {
            CalcFormula = lookup("Qlty. Test"."Test Value Type" where(Code = field("Test Code")));
            Caption = 'Test Value Type';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the value type of the Test. The program automatically retrieves the value from the Test Value Type field on the Test template.';
        }
        field(7; "Allowable Values"; Text[500])
        {
            CalcFormula = lookup("Qlty. Test"."Allowable Values" where(Code = field("Test Code")));
            Caption = 'Allowable Values';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies an expression for the range of values you can enter or select on the Quality Inspection line. The program automatically retrieves the value from the Allowable Values field on the Field template.';
        }
        field(10; "Copied From Template Code"; Code[20])
        {
            ToolTip = 'Specifies where a template was copied from.';
            Caption = 'Copied From Template Code';
        }
        field(11; "Default Value"; Text[250])
        {
            CalcFormula = lookup("Qlty. Test"."Default Value" where(Code = field("Test Code")));
            Caption = 'Default Value';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies a default value to set on the inspection.';
        }
        field(12; "Expression Formula"; Text[500])
        {
            Caption = 'Expression Formula';
            ToolTip = 'Specifies the formula for the expression content when using expression test value types.';

            trigger OnValidate()
            begin
                Rec.CalcFields("Test Value Type");
                if Rec."Expression Formula" <> '' then begin
                    if not (Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Text Expression"]) then
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
        key(Key2; "Template Code", "Test Code")
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
        Rec.CalcFields("Test Value Type");
    end;

    procedure InitLineNoIfNeeded()
    var
        ExistingsQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        if Rec."Line No." <> 0 then
            exit;

        ExistingsQltyInspectionTemplateLine.SetRange("Template Code", Rec."Template Code");
        ExistingsQltyInspectionTemplateLine.SetCurrentKey("Template Code", "Line No.");
        ExistingsQltyInspectionTemplateLine.Ascending(true);
        if ExistingsQltyInspectionTemplateLine.FindLast() then;
        Rec."Line No." := ExistingsQltyInspectionTemplateLine."Line No." + 10000;
    end;

    trigger OnModify()
    begin
        EnsureResultsExist(false);
        Rec.CalcFields("Test Value Type");
        if Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Text Expression"] then
            ValidateExpressionFormula();
    end;

    /// <summary>
    /// Ensures results exist for this template line.
    /// </summary>
    /// <param name="ForceOverwriteConditions"></param>
    procedure EnsureResultsExist(ForceOverwriteConditions: Boolean)
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.CopyResultConditionsFromTestToTemplateLine(Rec."Template Code", Rec."Line No.", '', ForceOverwriteConditions);
    end;

    /// <summary>
    /// This will validate the expression formula.
    /// </summary>
    procedure ValidateExpressionFormula()
    begin
        Rec.CalcFields("Test Value Type");

        OnValidateExpressionFormula(Rec);
    end;

    #region Add Multiple Tests
    internal procedure SelectMultipleTests()
    var
        SelectionFilter: Text;
    begin
        SelectionFilter := SelectInQltyTests();

        if SelectionFilter <> '' then
            AddTests(SelectionFilter);
    end;

    local procedure SelectInQltyTests(): Text
    var
        QltyTests: Page "Qlty. Tests";
    begin
        QltyTests.LookupMode(true);
        if QltyTests.RunModal() = Action::LookupOK then
            exit(QltyTests.GetSelectionFilter());
    end;

    local procedure AddTests(SelectionFilter: Text)
    var
        QltyTest: Record "Qlty. Test";
    begin
        QltyTest.SetFilter(Code, SelectionFilter);
        if QltyTest.FindSet() then
            repeat
                AddTestToTemplateLine(QltyTest.Code);
            until QltyTest.Next() = 0;
    end;

    local procedure AddTestToTemplateLine(QltyTestCode: Code[20])
    var
        ExistingQltyInspectionTemplateLine, NewQltyInspectionTemplateLine : Record "Qlty. Inspection Template Line";
    begin
        ExistingQltyInspectionTemplateLine.SetRange("Template Code", Rec."Template Code");
        ExistingQltyInspectionTemplateLine.SetRange("Test Code", QltyTestCode);
        if not ExistingQltyInspectionTemplateLine.IsEmpty() then
            exit;

        NewQltyInspectionTemplateLine.Init();
        NewQltyInspectionTemplateLine."Template Code" := Rec."Template Code";
        NewQltyInspectionTemplateLine.InitLineNoIfNeeded();
        NewQltyInspectionTemplateLine.Validate("Test Code", QltyTestCode);
        NewQltyInspectionTemplateLine.Insert(true);
        NewQltyInspectionTemplateLine.EnsureResultsExist(true);
        NewQltyInspectionTemplateLine.Modify();
    end;
    #endregion Add Multiple Tests

    /// <summary>
    /// Validates the expression formula.
    /// </summary>
    /// <param name="QltyInspectionTemplateLine"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateExpressionFormula(var QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line")
    begin
    end;
}
