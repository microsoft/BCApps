// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.Foundation.UOM;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Utilities;
using System.Environment.Configuration;
using System.Utilities;

/// <summary>
/// Contains the document lines for a quality order.
/// </summary>
table 20406 "Qlty. Inspection Test Line"
{
    Caption = 'Quality Inspection Test Line';
    LookupPageId = "Qlty. Inspection Test Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test No."; Code[20])
        {
            Description = 'The test header';
            Editable = false;
            OptimizeForTextSearch = true;
            Caption = 'Test No.';
            ToolTip = 'Specifies which test this is.';
        }
        field(2; "Retest No."; Integer)
        {
            Caption = 'Retest No.';
            ToolTip = 'Specifies which retest this is for.';
            Editable = false;
            BlankZero = true;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line no. of the test in this template.';
        }
        field(4; "Template Code"; Code[20])
        {
            Caption = 'Template Code';
            Editable = false;
            TableRelation = "Qlty. Inspection Test Header"."Template Code";
            ToolTip = 'Specifies which template this test was created from.';
        }
        field(5; "Template Line No."; Integer)
        {
            Caption = 'Quality Inspection Template Line No.';
            TableRelation = "Qlty. Inspection Template Line"."Line No." where("Template Code" = field("Template Code"));
            Editable = false;
            BlankZero = true;
        }
        field(12; "Field Code"; Code[20])
        {
            Caption = 'Field Code';
            NotBlank = true;
            TableRelation = "Qlty. Field".Code;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the field/question/metric in this test.';

            trigger OnValidate()
            var
                QltyField: Record "Qlty. Field";
            begin
                if "Field Code" = '' then
                    Rec.Description := ''
                else
                    if QltyField.Get("Field Code") then begin
                        Rec.Description := QltyField.Description;
                        Rec."Allowable Values" := QltyField."Allowable Values";
                        if Rec."Test Value" = '' then
                            Rec."Test Value" := QltyField."Default Value";
                    end;
            end;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
            Description = 'Specifies a description of the field as it is used on the test.';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies a description of the field as it is used on the test.';
        }
        field(14; "Field Type"; Enum "Qlty. Field Type")
        {
            CalcFormula = lookup("Qlty. Field"."Field Type" where(Code = field("Field Code")));
            Caption = 'Field Type';
            Description = 'Specifies the data type of the values you can enter or select for this field. Use Decimal for numerical measurements. Use Choice to give a list of options to choose from. If you want to choose options from an existing table, use Table Lookup.';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the data type of the values you can enter or select for this field. Use Decimal for numerical measurements. Use Choice to give a list of options to choose from. If you want to choose options from an existing table, use Table Lookup.';
        }
        field(16; "Allowable Values"; Text[500])
        {
            Caption = 'Allowable Values';
            Editable = false;
            ToolTip = 'Specifies an expression for the range of values you can enter or select for the Field. Depending on the Field Type, the expression format varies. For example if you want a measurement such as a percentage that collects between 0 and 100 you would enter 0..100. This is not the pass or acceptable condition, these are just the technically possible values that the inspector can enter. You would then enter a passing condition in your grade conditions. If you had a grade of Pass being 80 to 100, you would then configure 80..100 for that grade.';
        }
        field(18; "Test Value"; Text[250])
        {
            Caption = 'Test Value';
            Description = 'The recorded test value.';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the recorded test value.';

            trigger OnValidate()
            var
                QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
                Handled: Boolean;
            begin
                QltyInspectionTemplateLine.Get(Rec."Template Code", Rec."Template Line No.");
                ValidateTestValue();
                Rec."Numeric Value" := 0;
                OnBeforeEvaluateNumericTestValue(Rec, Handled);
                if not Handled then
                    if Evaluate(Rec."Numeric Value", Rec."Test Value") then;

                SetLargeText(Rec."Test Value", false, true);

                UpdateExpressionsInOtherTestLinesInSameTest();
            end;
        }
        field(19; "Test Value Blob"; Blob)
        {
            Description = 'When set, large test value data. Typically used for larger text that is captured.';
            Caption = 'Test Value Blob';
        }
        field(25; "Numeric Value"; Decimal)
        {
            Description = 'Specifies an evaluated numeric value of Test Value for use in calculations. eg: easier to use for Business Central charting.';
            Editable = false;
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            Caption = 'Numeric Value';
            ToolTip = 'Specifies an evaluated numeric value of Test Value for use in calculations. eg: easier to use for Business Central charting.';
        }
        field(28; "Grade Code"; Code[20])
        {
            Editable = false;
            Description = 'The grade is automatically determined based on the test value and grade configuration.';
            TableRelation = "Qlty. Inspection Grade".Code;
            Caption = 'Grade Code';
            ToolTip = 'Specifies the grade is automatically determined based on the test value and grade configuration.';

            trigger OnValidate()
            var
                QltyGrade: Record "Qlty. Inspection Grade";
            begin
                if QltyGrade.Get(Rec."Grade Code") then begin
                    Rec."Grade Priority" := QltyGrade."Evaluation Sequence";
                    Rec.CalcFields("Grade Description");
                end;
            end;
        }
        field(29; "Grade Description"; Text[100])
        {
            Caption = 'Grade';
            Description = 'The grade description for this test result. The grade is automatically determined based on the test value and grade configuration.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Qlty. Inspection Grade"."Description" where("Code" = field("Grade Code")));
            ToolTip = 'Specifies the grade description for this test result. The grade is automatically determined based on the test value and grade configuration.';
        }
        field(30; "Grade Priority"; Integer)
        {
            Editable = false;
            Description = 'The associated grade priority for this test result. The grade is automatically determined based on the test value and grade configuration.';
            Caption = 'Grade Priority';
            ToolTip = 'Specifies the associated grade priority for this test result. The grade is automatically determined based on the test value and grade configuration.';
        }
        field(33; "Failure State"; Enum "Qlty. Line Failure State")
        {
            Caption = 'Failure State';
            Editable = false;
        }
        field(34; "NCR Test No."; Code[20])
        {
            Caption = 'Non-Conformance Test No.';
            ToolTip = 'Specifies a free text editable reference to an NCR Test No.';
        }
        field(35; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure for the measurement.';
            TableRelation = "Unit of Measure".Code;
        }
    }

    keys
    {
        key(Key1; "Test No.", "Retest No.", "Line No.")
        {
            Clustered = true;
        }
        key(byGrade; "Template Code", "Test No.", "Retest No.", "Field Code", "Grade Code")
        {
            SumIndexFields = "Grade Priority";
        }
        key(byGradePriority; "Template Code", "Test No.", "Retest No.", "Grade Priority")
        {
        }
        key(byDate; "Template Code", "Test No.", "Retest No.", "Field Code", SystemCreatedAt, SystemModifiedAt)
        {
        }
    }

    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        BooleanChoiceListLbl: Label 'No,Yes';

    trigger OnModify()
    begin
        if not Rec.IsTemporary() then
            TestStatusOpen();

        Rec."Numeric Value" := 0;
        if Evaluate(Rec."Numeric Value", Rec."Test Value") then;
    end;

    trigger OnDelete()
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Test);
        QltyIGradeConditionConf.SetRange("Target Code", Rec."Test No.");
        QltyIGradeConditionConf.SetRange("Target Retest No.", Rec."Retest No.");
        QltyIGradeConditionConf.SetRange("Target Line No.", Rec."Line No.");
        QltyIGradeConditionConf.DeleteAll();
    end;

    protected procedure ValidateTestValue()
    var
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
    begin
        GetTest();
        QltyGradeEvaluation.ValidateTestLine(Rec, QltyInspectionTestHeader, true);
    end;

    local procedure GetTest(): Boolean
    begin
        if Rec.IsTemporary() then
            exit(false);

        exit(QltyInspectionTestHeader.Get(Rec."Test No.", Rec."Retest No."));
    end;

    local procedure TestStatusOpen()
    begin
        if GetTest() then
            QltyInspectionTestHeader.TestField(Status, QltyInspectionTestHeader.Status::Open);
    end;

    /// <summary>
    /// Starts the appropriate 'assist edit' dialog for the given data type and conditions.
    /// </summary>
    procedure AssistEditTestValue()
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        Rec.CalcFields("Field Type");
        if QltyInspectionTemplateLine.Get(Rec."Template Code", Rec."Template Line No.") then;

        if Rec."Allowable Values" = '' then
            if QltyInspectionTemplateLine."Template Code" <> '' then begin
                QltyInspectionTemplateLine.CalcFields("Allowable Values");
                Rec."Allowable Values" := QltyInspectionTemplateLine."Allowable Values";
            end;

        case Rec."Field Type" of
            Rec."Field Type"::"Field Type Option":
                AssistEditChooseFromList(Rec."Allowable Values");
            Rec."Field Type"::"Field Type Table Lookup":
                AssistEditChooseFromTableLookup();
            Rec."Field Type"::"Field Type Boolean":
                AssistEditChooseFromList(BooleanChoiceListLbl);
            Rec."Field Type"::"Field Type Text":
                AssistEditFreeText();
        end;
    end;

    procedure AssistEditFreeText()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        ExistingText: Text;
    begin
        ExistingText := GetLargeText();

        if QltyEditLargeText.RunModalWith(ExistingText) in [Action::LookupOK, Action::OK, Action::Yes] then
            SetLargeText(ExistingText, true, false);
    end;

    procedure GetLargeText() Result: Text
    var
        InStreamForText: InStream;
    begin
        Result := Rec."Test Value";

        if Rec.CalcFields("Test Value Blob") then begin
            Rec."Test Value Blob".CreateInStream(InStreamForText);
            InStreamForText.Read(Result);
            if (StrLen(Result) < 1) and (StrLen(Rec."Test Value") > 0) then
                Result := Rec."Test Value";
        end;
    end;

    procedure SetLargeText(LargeText: Text; ValidateValue: Boolean; OnlySetBlob: Boolean)
    var
        OutStreamForText: OutStream;
    begin
        if not OnlySetBlob then
            if ValidateValue then
                Rec.Validate("Test Value", CopyStr(LargeText, 1, MaxStrLen(Rec."Test Value")))
            else
                Rec."Test Value" := CopyStr(LargeText, 1, MaxStrLen(Rec."Test Value"));

        if Rec."Field Type" in [Rec."Field Type"::"Field Type Text"] then begin
            Clear(Rec."Test Value Blob");
            Rec."Test Value Blob".CreateOutStream(OutStreamForText);
            OutStreamForText.WriteText(LargeText);
            Rec.Modify();
        end;
    end;

    local procedure AssistEditChooseFromList(Options: Text)
    var
        Selection: Integer;
    begin
        Selection := StrMenu(Options.Replace(', ', ','));
        if Selection > 0 then
            Rec.Validate("Test Value", SelectStr(Selection, Options));
    end;

    local procedure AssistEditChooseFromTableLookup()
    var
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
    begin
        CollectAllowableValues(TempBufferQltyLookupCode);

        if Page.RunModal(Page::"Qlty. Lookup Field Choose", TempBufferQltyLookupCode) = Action::LookupOK then
            Rec.Validate("Test Value", CopyStr(TempBufferQltyLookupCode."Custom 1", 1, MaxStrLen(Rec."Test Value")));
    end;

    /// <summary>
    /// Code = the unique code
    /// Description = raw description.
    /// Custom 1 = original value
    /// Custom 2 = lowercase value
    /// Custom 3 = uppercase value.
    /// </summary>
    /// <param name="TempBufferQltyLookupCode"></param>
    internal procedure CollectAllowableValues(var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary)
    var
        QltyField: Record "Qlty. Field";
    begin
        Rec.CalcFields("Field Type");
        if not QltyField.Get(Rec."Field Code") then
            exit;

        if not GetTest() then;
        QltyField.CollectAllowableValues(QltyInspectionTestHeader, Rec, TempBufferQltyLookupCode, Rec."Test Value");
    end;

    /// <summary>
    /// Returns true if the field is a numeric field type.
    /// </summary>
    /// <returns></returns>
    procedure IsNumericFieldType(): Boolean
    var
        QltyField: Record "Qlty. Field";
    begin
        if Rec."Field Code" <> '' then
            if QltyField.Get(Rec."Field Code") then
                exit(QltyField.IsNumericFieldType());
    end;

    procedure GetFailedSampleCount() FailedSamples: Integer
    begin
    end;

    /// <summary>
    /// Gets the preferred grade style to use.
    /// </summary>
    procedure GetGradeStyle(): Text
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
    begin
        if QltyInspectionGrade.Get(Rec."Grade Code") then
            exit(QltyInspectionGrade.GetGradeStyle());
    end;

    procedure UpdateExpressionsInOtherTestLinesInSameTest()
    var
        OthersInSameQltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        OfConsideredFields: List of [Text];
    begin
        if not GetTest() then
            exit;

        OthersInSameQltyInspectionTestLine.SetRange("Test No.", Rec."Test No.");
        OthersInSameQltyInspectionTestLine.SetRange("Retest No.", Rec."Retest No.");
        OthersInSameQltyInspectionTestLine.SetFilter("Field Type", '%1', QltyInspectionTemplateLine."Field Type"::"Field Type Text Expression");
        OthersInSameQltyInspectionTestLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        OthersInSameQltyInspectionTestLine.SetAutoCalcFields("Field Type");

        QltyInspectionTemplateLine.SetRange("Template Code", Rec."Template Code");
        QltyInspectionTemplateLine.SetFilter("Field Type", '%1', QltyInspectionTemplateLine."Field Type"::"Field Type Text Expression");
        QltyInspectionTemplateLine.SetFilter("Field Code", '<>%1', Rec."Field Code");
        QltyInspectionTemplateLine.SetAutoCalcFields("Field Type");
        if QltyInspectionTemplateLine.FindSet() then
            repeat
                OthersInSameQltyInspectionTestLine.SetRange("Template Line No.", QltyInspectionTemplateLine."Line No.");
                OthersInSameQltyInspectionTestLine.SetRange("Field Code", QltyInspectionTemplateLine."Field Code");
                if OthersInSameQltyInspectionTestLine.FindSet() then
                    repeat
                        OfConsideredFields.Add(OthersInSameQltyInspectionTestLine."Field Code");
                        case OthersInSameQltyInspectionTestLine."Field Type" of
                            OthersInSameQltyInspectionTestLine."Field Type"::"Field Type Text Expression":
                                OthersInSameQltyInspectionTestLine.EvaluateTextExpression(QltyInspectionTestHeader);
                        end;
                    until OthersInSameQltyInspectionTestLine.Next() = 0;
            until QltyInspectionTemplateLine.Next() = 0;

        QltyGradeEvaluation.GetTestLineConfigFilters(Rec, QltyIGradeConditionConf);
        QltyIGradeConditionConf.SetFilter("Target Line No.", '<>%1', Rec."Line No.");
        QltyIGradeConditionConf.SetFilter("Field Code", '<>%1', Rec."Field Code");
        QltyIGradeConditionConf.SetFilter("Condition", StrSubstNo('@*[%1]*', Rec."Field Code"));
        QltyIGradeConditionConf.SetLoadFields("Target Line No.", "Field Code");
        OthersInSameQltyInspectionTestLine.Reset();
        if QltyIGradeConditionConf.FindSet() then
            repeat
                OthersInSameQltyInspectionTestLine.SetRange("Test No.", Rec."Test No.");
                OthersInSameQltyInspectionTestLine.SetRange("ReTest No.", Rec."ReTest No.");
                OthersInSameQltyInspectionTestLine.SetRange("Line No.", QltyIGradeConditionConf."Target Line No.");
                OthersInSameQltyInspectionTestLine.SetRange("Field Code", QltyIGradeConditionConf."Field Code");
                if OthersInSameQltyInspectionTestLine.FindFirst() then begin
                    OfConsideredFields.Add(OthersInSameQltyInspectionTestLine."Field Code");
                    OthersInSameQltyInspectionTestLine.ValidateTestValue();
                end;
            until QltyIGradeConditionConf.Next() = 0;

        OthersInSameQltyInspectionTestLine.Reset();
        OthersInSameQltyInspectionTestLine.SetRange("Test No.", Rec."Test No.");
        OthersInSameQltyInspectionTestLine.SetRange("Retest No.", Rec."Retest No.");
        OthersInSameQltyInspectionTestLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        OthersInSameQltyInspectionTestLine.SetFilter("Allowable Values", StrSubstNo('@*[%1]*', Rec."Field Code"));
        if OthersInSameQltyInspectionTestLine.FindSet(true) then
            repeat
                if not OfConsideredFields.Contains(OthersInSameQltyInspectionTestLine."Field Code") then
                    OthersInSameQltyInspectionTestLine.ValidateTestValue();

            until OthersInSameQltyInspectionTestLine.Next() = 0;
    end;

    internal procedure EvaluateTextExpression(var EvaluateAgainstQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        QltyExpressionMgmt.EvaluateTextExpression(Rec, EvaluateAgainstQltyInspectionTestHeader);
    end;

    /// <summary>
    /// Reads the last measurement note for the specific test line.
    /// If there are multiple notes it only reads the last one.
    /// </summary>
    /// <returns></returns>
    procedure GetMeasurementNote() Note: Text
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange("Record ID", Rec.RecordId());
        if RecordLink.FindLast() then begin
            RecordLink.CalcFields(Note);
            Note := RecordLinkManagement.ReadNote(RecordLink);
        end;
    end;

    /// <summary>
    /// Sets the measurement note on the last associated note line for the test line.
    /// If there is no note record yet (record link) then it will create a new one.
    /// </summary>
    /// <param name="Note"></param>
    procedure SetMeasurementNote(Note: Text)
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.TestCanEditLineComments();

        GetTest();
        QltyInspectionTestHeader.TestField(Status, QltyInspectionTestHeader.Status::Open);

        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange("Record ID", Rec.RecordId());
        if not RecordLink.FindLast() then begin
            RecordLink.Init();
            RecordLink."Link ID" := 0;
            RecordLink."Record ID" := Rec.RecordId();
            RecordLink.URL1 := '';
            RecordLink.Type := RecordLink.Type::Note;
            RecordLink.Created := CurrentDateTime();
            RecordLink."User ID" := CopyStr(UserId(), 1, MaxStrLen(RecordLink."User ID"));
            RecordLink.Company := CopyStr(CompanyName(), 1, MaxStrLen(RecordLink.Company));
            RecordLink.Notify := true;
            RecordLinkManagement.WriteNote(RecordLink, Note);
            RecordLink.Insert(false);
        end else begin
            Clear(RecordLink.Note);
            RecordLinkManagement.WriteNote(RecordLink, Note);
            RecordLink.Modify();
        end;
    end;

    /// <summary>
    /// Opens up a dialog to collect note text.
    /// </summary>
    procedure RunModalEditMeasurementNote()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        Note: Text;
    begin
        GetTest();
        QltyInspectionTestHeader.TestField(Status, QltyInspectionTestHeader.Status::Open);

        Note := GetMeasurementNote();
        if QltyEditLargeText.RunModalWith(Note) in [Action::LookupOK, Action::OK, Action::Yes] then
            SetMeasurementNote(Note);
    end;

    /// <summary>
    /// Opens up a dialog to collect note text.
    /// </summary>
    procedure RunModalReadOnlyComment()
    var
        QltyEditLargeText: Page "Qlty. Edit Large Text";
        Note: Text;
    begin
        Note := GetMeasurementNote();
        QltyEditLargeText.RunModalWith(Note);
    end;

    /// <summary>
    /// Provides an opportunity to modify the evaluation of the Numeric Test Value from the Test Value.
    /// </summary>
    /// <param name="QltyInspectionTestLine">Qlty. Test Line</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateNumericTestValue(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var Handled: Boolean)
    begin
    end;
}
