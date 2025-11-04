// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using System.DateTime;
using System.Utilities;

/// <summary>
/// Methods to help with grade evaluation.
/// </summary>
codeunit 20410 "Qlty. Grade Evaluation"
{
    TableNo = "Qlty. Inspection Test Line";

    var
        IsDefaultNumberTok: Label '<>0', Locked = true;
        IsDefaultTextTok: Label '<>''''', Locked = true;
        InvalidDataTypeErr: Label 'The value "%1" is not allowed for %2, it is not a %3.', Comment = '%1=the value, %2=field name,%3=field type.';
        NotInAllowableValuesErr: Label 'The value "%1" is not allowed for %2, it must be in the range of "%3".', Comment = '%1=the value, %2=field name,%3=field type.';

    trigger OnRun()
    var
        OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        if (not Rec.IsTemporary()) and (Rec."Test No." <> '') then
            OptionalQltyInspectionTestHeader.Get(Rec."Test No.", Rec."Retest No.");
        ValidateTestLine(Rec, OptionalQltyInspectionTestHeader, true);
    end;

    /// <summary>
    /// Evaluates a grade with an optional test.
    /// The test is used to help with expression evaluation.
    /// </summary>
    /// <param name="OptionalQltyInspectionTestHeader"></param>
    /// <param name="TestQltyIGradeConditionConf"></param>
    /// <param name="QltyFieldType"></param>
    /// <param name="TestValue"></param>
    /// <param name="CaseOption"></param>
    /// <returns></returns>
    internal procedure EvaluateGrade(var OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyFieldType: Enum "Qlty. Field Type"; TestValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Code[20]
    var
        TempNotUsedOptionalQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
    begin
        exit(EvaluateGrade(OptionalQltyInspectionTestHeader, TempNotUsedOptionalQltyInspectionTestLine, TestQltyIGradeConditionConf, QltyFieldType, TestValue, QltyCaseSensitivity));
    end;

    /// <summary>
    /// Evaluates a grade with an optional test and test line.
    /// The test is used to help with expression evaluation.
    /// </summary>
    /// <param name="OptionalQltyInspectionTestHeader"></param>
    /// <param name="TestQltyIGradeConditionConf"></param>
    /// <param name="QltyFieldType"></param>
    /// <param name="TestValue"></param>
    /// <param name="CaseOption"></param>
    /// <returns></returns>
    procedure EvaluateGrade(var OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var OptionalQltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf."; QltyFieldType: Enum "Qlty. Field Type"; TestValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity") Result: Code[20]
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        TempHighestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf." temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        LoopConditionMet: Boolean;
        AnyConditionMet: Boolean;
        Handled: Boolean;
        Small: Text[250];
        Condition: Text;
    begin
        OnBeforeEvaluateGrade(TestQltyIGradeConditionConf, QltyFieldType, TestValue, Result, Handled);
        if Handled then
            exit;

        QltyInspectionGrade.SetCurrentKey("Evaluation Sequence");
        QltyInspectionGrade.Ascending();
        if not QltyInspectionGrade.FindSet() then
            exit;

        repeat
            TestQltyIGradeConditionConf.SetRange("Grade Code", QltyInspectionGrade.Code);
            if TestQltyIGradeConditionConf.FindSet() then
                repeat
                    LoopConditionMet := false;

                    Condition := TestQltyIGradeConditionConf.Condition;
                    if Condition.Contains('[') then
                        Condition := QltyExpressionMgmt.EvaluateTextExpression(Condition, OptionalQltyInspectionTestHeader, OptionalQltyInspectionTestLine);

                    if Condition.Contains('{') then
                        Condition := QltyExpressionMgmt.EvaluateEmbeddedNumericalExpressions(Condition, OptionalQltyInspectionTestHeader);

                    case QltyFieldType of
                        QltyFieldType::"Field Type Decimal":
                            LoopConditionMet := TestValueDecimal(TestValue, Condition);
                        QltyFieldType::"Field Type Integer":
                            LoopConditionMet := TestValueInteger(TestValue, Condition);
                        QltyFieldType::"Field Type Boolean":
                            if QltyMiscHelpers.CanTextBeInterpretedAsBooleanIsh(TestValue) and
                               QltyMiscHelpers.CanTextBeInterpretedAsBooleanIsh(Condition)
                            then
                                LoopConditionMet := QltyMiscHelpers.GetBooleanFor(TestValue) = QltyMiscHelpers.GetBooleanFor(Condition)
                            else
                                LoopConditionMet := TestValueString(TestValue, Condition, QltyCaseSensitivity);
                        QltyFieldType::"Field Type Text", QltyFieldType::"Field Type Option", QltyFieldType::"Field Type Table Lookup", QltyFieldType::"Field Type Text Expression":
                            LoopConditionMet := TestValueString(TestValue, Condition, QltyCaseSensitivity);
                        QltyFieldType::"Field Type Date":
                            begin
                                Small := CopyStr(TestValue, 1, MaxStrLen(Small));
                                LoopConditionMet := TestValueDate(Small, Condition, false);
                                TestValue := Small;
                            end;
                        QltyFieldType::"Field Type DateTime":
                            begin
                                Small := CopyStr(TestValue, 1, MaxStrLen(Small));
                                LoopConditionMet := TestValueDateTime(Small, Condition, false);
                                TestValue := Small;
                            end;
                        QltyFieldType::"Field Type Label":
                            LoopConditionMet := true;
                    end;
                    if LoopConditionMet then begin
                        AnyConditionMet := true;
                        TempHighestQltyIGradeConditionConf := TestQltyIGradeConditionConf;
                    end;
                until TestQltyIGradeConditionConf.Next() = 0;

        until QltyInspectionGrade.Next() = 0;

        OnAfterEvaluateGrade(TestQltyIGradeConditionConf, QltyFieldType, TestValue, Result, TempHighestQltyIGradeConditionConf, Handled);
        if Handled then
            exit;

        if AnyConditionMet then
            exit(TempHighestQltyIGradeConditionConf."Grade Code");
    end;

    /// <summary>
    /// Call this procedure to validate the test line.
    /// </summary>
    /// <param name="QltyInspectionTestLine"></param>
    internal procedure ValidateTestLine(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line")
    var
        OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        if (not QltyInspectionTestLine.IsTemporary()) and (QltyInspectionTestLine."Test No." <> '') then
            if OptionalQltyInspectionTestHeader.Get(QltyInspectionTestLine."Test No.", QltyInspectionTestLine."Retest No.") then;
        ValidateTestLine(QltyInspectionTestLine, OptionalQltyInspectionTestHeader, true);
    end;

    /// <summary>
    /// This will *not* modify the test line.
    /// This will only try and validate the test line itself.
    /// </summary>
    /// <param name="QltyInspectionTestLine"></param>
    /// <param name="OptionalQltyInspectionTestHeader"></param>
    /// <returns></returns>
    [TryFunction]
    procedure TryValidateTestLine(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    begin
        ValidateTestLine(QltyInspectionTestLine, OptionalQltyInspectionTestHeader, false);
    end;

    /// <summary>
    /// Call this procedure to validate the test line for the given test.
    /// </summary>
    /// <param name="QltyInspectionTestLine"></param>
    /// <param name="OptionalQltyInspectionTestHeader"></param>
    /// <param name="Modify">Set to true to modify the grade(default), false to avoid modifying.</param>
    procedure ValidateTestLine(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; Modify: Boolean)
    begin
        ValidateTestLineWithAllowableValues(QltyInspectionTestLine, OptionalQltyInspectionTestHeader, true, Modify);
    end;

    procedure ValidateTestLineWithAllowableValues(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; CheckForAllowableValues: Boolean; Modify: Boolean)
    var
        QltyField: Record "Qlty. Field";
        TestLineQltyInspectionGrade: Record "Qlty. Inspection Grade";
        TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        Grade: Code[20];
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
    begin
        QltyInspectionTestLine.CalcFields("Field Type");

        if CheckForAllowableValues then
            ValidateAllowableValuesOnTestLine(QltyInspectionTestLine, OptionalQltyInspectionTestHeader);

        GetTestGradeConditionConfigFilters(QltyInspectionTestLine, TestQltyIGradeConditionConf);

        QltyCaseSensitivity := QltyCaseSensitivity::Sensitive;
        if QltyField.Get(QltyInspectionTestLine."Field Code") then
            QltyCaseSensitivity := QltyField."Case Sensitive";

        Grade := EvaluateGrade(OptionalQltyInspectionTestHeader, QltyInspectionTestLine, TestQltyIGradeConditionConf, QltyInspectionTestLine."Field Type", QltyInspectionTestLine."Test Value", QltyCaseSensitivity);

        QltyInspectionTestLine."Failure State" := QltyInspectionTestLine."Failure State"::" ";
        if Grade <> '' then begin
            TestLineQltyInspectionGrade.Get(Grade);
            if TestLineQltyInspectionGrade."Grade Category" = TestLineQltyInspectionGrade."Grade Category"::"Not acceptable" then
                QltyInspectionTestLine."Failure State" := QltyInspectionTestLine."Failure State"::"Failed from Acceptance Criteria";
        end;

        QltyInspectionTestLine.Validate("Grade Code", Grade);

        if Modify then
            QltyInspectionTestLine.Modify(true);

        if (not QltyInspectionTestLine.IsTemporary()) and (OptionalQltyInspectionTestHeader."No." <> '') and (QltyInspectionTestLine."Test No." <> '') then begin
            OptionalQltyInspectionTestHeader.UpdateGradeFromLines();
            OptionalQltyInspectionTestHeader.Validate("Grade Code");
            if Modify then
                if OptionalQltyInspectionTestHeader.Modify(true) then;
        end;
    end;

    procedure GetTestLineConfigFilters(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var TemplateLineQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.")
    begin
        TemplateLineQltyIGradeConditionConf.SetRange("Condition Type", TemplateLineQltyIGradeConditionConf."Condition Type"::Test);
        TemplateLineQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTestLine."Test No.");
        TemplateLineQltyIGradeConditionConf.SetRange("Target Retest No.", QltyInspectionTestLine."Retest No.");
        TemplateLineQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTestLine."Line No.");
        TemplateLineQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTestLine."Field Code");
    end;

    local procedure GetTestGradeConditionConfigFilters(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.")
    begin
        TestQltyIGradeConditionConf.Reset();
        TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Test);
        TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTestLine."Test No.");
        TestQltyIGradeConditionConf.SetRange("Target Retest No.", QltyInspectionTestLine."Retest No.");
        TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTestLine."Line No.");
        TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTestLine."Field Code");

        if TestQltyIGradeConditionConf.IsEmpty() then begin
            TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Template);
            TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTestLine."Template Code");
            TestQltyIGradeConditionConf.SetRange("Target Retest No.");
            TestQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionTestLine."Template Line No.");
            TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTestLine."Field Code");
            if TestQltyIGradeConditionConf.IsEmpty() then begin
                TestQltyIGradeConditionConf.SetRange("Condition Type", TestQltyIGradeConditionConf."Condition Type"::Field);
                TestQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionTestLine."Field Code");
                TestQltyIGradeConditionConf.SetRange("Target Retest No.");
                TestQltyIGradeConditionConf.SetRange("Target Line No.");
                TestQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionTestLine."Field Code");
            end;
        end;
    end;

    local procedure ValidateAllowableValuesOnTestLine(var QltyInspectionTestLine: Record "Qlty. Inspection Test Line"; var OptionalQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        QltyField: Record "Qlty. Field";
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
        FieldNameForError: Text;
        AllowableValues: Text;
    begin
        QltyInspectionTestLine.CalcFields("Field Type");
        if QltyInspectionTestLine."Test Value" = '' then
            exit;

        if QltyInspectionTestLine.Description <> '' then
            FieldNameForError := QltyInspectionTestLine.Description
        else
            FieldNameForError := QltyInspectionTestLine."Field Code";

        if QltyInspectionTestLine."Field Type" in [QltyInspectionTestLine."Field Type"::"Field Type Option", QltyInspectionTestLine."Field Type"::"Field Type Table Lookup"] then
            QltyInspectionTestLine.CollectAllowableValues(TempBufferQltyLookupCode);

        QltyCaseSensitivity := QltyCaseSensitivity::Sensitive;
        if QltyField.Get(QltyInspectionTestLine."Field Code") then
            QltyCaseSensitivity := QltyField."Case Sensitive";

        if QltyInspectionTestLine.IsTemporary() and (QltyInspectionTestLine."Field Type" in [QltyInspectionTestLine."Field Type"::"Field Type Option", QltyInspectionTestLine."Field Type"::"Field Type Table Lookup"]) then
            QltyCaseSensitivity := QltyCaseSensitivity::Insensitive;

        AllowableValues := QltyInspectionTestLine."Allowable Values";
        if AllowableValues.Contains('[') then
            AllowableValues := QltyExpressionMgmt.EvaluateTextExpression(AllowableValues, OptionalQltyInspectionTestHeader, QltyInspectionTestLine);

        if AllowableValues.Contains('{') then
            AllowableValues := QltyExpressionMgmt.EvaluateEmbeddedNumericalExpressions(AllowableValues, OptionalQltyInspectionTestHeader);

        ValidateAllowableValuesOnText(
            FieldNameForError,
            QltyInspectionTestLine."Test Value",
            AllowableValues,
            QltyInspectionTestLine."Field Type",
            TempBufferQltyLookupCode,
            QltyCaseSensitivity);
    end;

    procedure ValidateAllowableValuesOnField(var QltyField: Record "Qlty. Field")
    var
        TempDummyQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        TempDummyQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
    begin
        ValidateAllowableValuesOnField(QltyField, TempDummyQltyInspectionTestHeader, TempDummyQltyInspectionTestLine);
    end;

    internal procedure ValidateAllowableValuesOnField(var QltyField: Record "Qlty. Field"; var OptionalContextQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        TempDummyQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
    begin
        ValidateAllowableValuesOnField(QltyField, OptionalContextQltyInspectionTestHeader, TempDummyQltyInspectionTestLine);
    end;

    procedure ValidateAllowableValuesOnField(var QltyField: Record "Qlty. Field"; var OptionalContextQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var OptionalContextQltyInspectionTestLine: Record "Qlty. Inspection Test Line")
    var
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
        FieldNameForError: Text;
    begin
        if QltyField.Description <> '' then
            FieldNameForError := QltyField.Description
        else
            FieldNameForError := QltyField.Code;

        if QltyField."Field Type" in [QltyField."Field Type"::"Field Type Option", QltyField."Field Type"::"Field Type Table Lookup"] then
            QltyField.CollectAllowableValues(OptionalContextQltyInspectionTestHeader, OptionalContextQltyInspectionTestLine, TempBufferQltyLookupCode, QltyField."Default Value");

        QltyCaseSensitivity := QltyField."Case Sensitive";

        if QltyField.IsTemporary() and (QltyField."Field Type" in [QltyField."Field Type"::"Field Type Option", QltyField."Field Type"::"Field Type Table Lookup"]) then
            QltyCaseSensitivity := QltyCaseSensitivity::Insensitive;

        ValidateAllowableValuesOnText(FieldNameForError, QltyField."Default Value", QltyField."Allowable Values", QltyField."Field Type", TempBufferQltyLookupCode, QltyCaseSensitivity);
    end;

    local procedure ValidateAllowableValuesOnText(NumberOrNameOfFieldNameForError: Text; var TextToValidate: Text[250]; AllowableValues: Text; QltyFieldType: Enum "Qlty. Field Type"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity")
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
        ValueAsDecimal: Decimal;
        ValueAsInteger: Integer;
        DateAndTimeValue: DateTime;
        DateOnlyValue: Date;
        Handled: Boolean;
    begin
        OnBeforeValidateAllowableValuesOnText(NumberOrNameOfFieldNameForError, TextToValidate, AllowableValues, QltyFieldType, TempBufferQltyLookupCode, QltyCaseSensitivity, Handled);
        if Handled then
            exit;

        if TextToValidate = '' then
            exit;

        case QltyFieldType of
            QltyFieldType::"Field Type Decimal":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(ValueAsDecimal, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);

                    if not QltyGradeEvaluation.TestValueDecimal(TextToValidate, AllowableValues) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                end;
            QltyFieldType::"Field Type Integer":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(ValueAsInteger, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);

                    if not QltyGradeEvaluation.TestValueInteger(TextToValidate, AllowableValues) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                end;
            QltyFieldType::"Field Type DateTime":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(DateAndTimeValue, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);
                    if not QltyGradeEvaluation.TestValueDateTime(TextToValidate, AllowableValues, true) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);
                end;
            QltyFieldType::"Field Type Date":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(DateOnlyValue, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);

                    if not QltyGradeEvaluation.TestValueDate(TextToValidate, AllowableValues, true) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                end;
            QltyFieldType::"Field Type Boolean":
                begin
                    if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then
                        if QltyMiscHelpers.GetBooleanFor(TextToValidate) then
                            TextToValidate := QltyMiscHelpers.GetTranslatedYes250()
                        else
                            TextToValidate := QltyMiscHelpers.GetTranslatedNo250();

                    if (AllowableValues <> '') and (QltyMiscHelpers.CanTextBeInterpretedAsBooleanIsh(AllowableValues)) then begin
                        if not QltyMiscHelpers.GetBooleanFor(TextToValidate) = QltyMiscHelpers.GetBooleanFor(AllowableValues) then
                            Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                    end else
                        if not (TextToValidate in [QltyMiscHelpers.GetTranslatedYes250(), QltyMiscHelpers.GetTranslatedNo250(), '']) then
                            Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                end;
            QltyFieldType::"Field Type Text":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then
                    if not QltyGradeEvaluation.TestValueString(TextToValidate, ConvertStr(AllowableValues, ',', '|'), QltyCaseSensitivity) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);

            QltyFieldType::"Field Type Option",
                QltyFieldType::"Field Type Table Lookup":
                begin
                    TempBufferQltyLookupCode.Reset();
                    TempBufferQltyLookupCode.SetRange("Custom 1", TextToValidate);
                    if (TempBufferQltyLookupCode.IsEmpty()) and (QltyCaseSensitivity = QltyCaseSensitivity::Insensitive) then begin
                        TempBufferQltyLookupCode.Reset();
                        TempBufferQltyLookupCode.SetRange("Custom 2", TextToValidate.ToLower());
                    end;
                    if TempBufferQltyLookupCode.IsEmpty() then begin
                        TempBufferQltyLookupCode.Reset();
                        if QltyCaseSensitivity = QltyCaseSensitivity::Insensitive then
                            TempBufferQltyLookupCode.SetFilter("Custom 2", '%1', '@' + TextToValidate.ToLower() + '*')
                        else
                            TempBufferQltyLookupCode.SetFilter("Custom 1", '%1', TextToValidate + '*');
                    end;
                    if TempBufferQltyLookupCode.Count() = 1 then begin
                        TempBufferQltyLookupCode.FindFirst();
                        TextToValidate := CopyStr(TempBufferQltyLookupCode."Custom 1", 1, MaxStrLen(TextToValidate));
                    end else
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                end;
        end;
        OnAfterValidateAllowableValuesOnText(NumberOrNameOfFieldNameForError, TextToValidate, AllowableValues, QltyFieldType, TempBufferQltyLookupCode, QltyCaseSensitivity);
    end;

    internal procedure TestValueDecimal(TestValue: Text; AcceptableValue: Text): Boolean
    var
        TempNumericalQltyInspectionTestLine: Record "Qlty. Inspection Test Line" temporary;
        TestValueAsDecimal: Decimal;
    begin
        if TestValue = '' then
            TestValueAsDecimal := 0
        else
            Evaluate(TestValueAsDecimal, TestValue);

        if (AcceptableValue = '') and (TestValue <> '') then
            exit(true);

        if AcceptableValue = '<>''''' then
            AcceptableValue := '<>0';

        if (TestValue = '') and not (AcceptableValue in ['', '=''''', '<>0']) then
            exit(false);

        TempNumericalQltyInspectionTestLine."Numeric Value" := TestValueAsDecimal;
        if TempNumericalQltyInspectionTestLine.Insert(false) then;
        TempNumericalQltyInspectionTestLine.SetFilter("Numeric Value", AcceptableValue);
        exit(not TempNumericalQltyInspectionTestLine.IsEmpty());
    end;

    internal procedure TestValueInteger(TestValue: Text; AcceptableValue: Text): Boolean
    var
        TempInteger: Record "Integer" temporary;
        ValueAsInteger: Integer;
    begin
        if TestValue = '' then
            ValueAsInteger := 0
        else
            Evaluate(ValueAsInteger, TestValue);

        if (AcceptableValue = '') and (TestValue <> '') then
            exit(true);

        if AcceptableValue = '<>''''' then
            AcceptableValue := '<>0';

        if (TestValue = '') and not (AcceptableValue in ['', '=''''', '<>0']) then
            exit(false);

        TempInteger.Number := ValueAsInteger;
        TempInteger.Insert();
        TempInteger.SetFilter(Number, AcceptableValue);
        exit(not TempInteger.IsEmpty());
    end;

    local procedure IsBlankOrEmptyCondition(AcceptableValue: Text) Result: Boolean
    begin
        Result := AcceptableValue in ['', '  '];
    end;

    local procedure IsAnythingExceptEmptyCondition(AcceptableValue: Text) Result: Boolean
    begin
        Result := AcceptableValue in [IsDefaultNumberTok, IsDefaultTextTok];
    end;

    procedure TestValueDateTime(var TestValue: Text[250]; AcceptableValue: Text; AdjustTestValueIfGood: Boolean) IsGood: Boolean
    var
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        ValueAsDateTime: DateTime;
    begin
        if TestValue = '' then
            ValueAsDateTime := 0DT
        else
            Evaluate(ValueAsDateTime, TestValue);

        if IsAnythingExceptEmptyCondition(AcceptableValue) then
            if TestValue <> '' then begin
                IsGood := true;
                if AdjustTestValueIfGood then
                    TestValue := CopyStr(Format(ValueAsDateTime, 0, 9), 1, MaxStrLen(TestValue));

                exit(IsGood);
            end else begin
                IsGood := false;
                exit(IsGood);
            end;

        if IsBlankOrEmptyCondition(AcceptableValue) then
            if TestValue <> '' then begin
                IsGood := true;
                if AdjustTestValueIfGood then
                    TestValue := CopyStr(Format(ValueAsDateTime, 0, 9), 1, MaxStrLen(TestValue));

                exit(IsGood);
            end else begin
                IsGood := true;
                exit(IsGood);
            end;

        TempQltyInspectionTestHeader."Finished Date" := ValueAsDateTime;
        TempQltyInspectionTestHeader.Insert();
        TempQltyInspectionTestHeader.SetFilter("Finished Date", AcceptableValue);
        IsGood := not TempQltyInspectionTestHeader.IsEmpty();
        if IsGood and AdjustTestValueIfGood then
            TestValue := CopyStr(Format(ValueAsDateTime, 0, 9), 1, MaxStrLen(TestValue));

        exit(IsGood);
    end;

    procedure TestValueDate(var TestValue: Text[250]; AcceptableValue: Text; AdjustTestValueIfGood: Boolean) IsGood: Boolean
    var
        TempDateLookupBuffer: Record "Date Lookup Buffer" temporary;
        ValueAsDate: Date;
    begin
        if TestValue = '' then
            ValueAsDate := 0D
        else
            Evaluate(ValueAsDate, TestValue);

        if IsAnythingExceptEmptyCondition(AcceptableValue) then
            if TestValue <> '' then begin
                IsGood := true;
                if AdjustTestValueIfGood then
                    TestValue := CopyStr(Format(ValueAsDate, 0, 9), 1, MaxStrLen(TestValue));

                exit(IsGood);
            end else begin
                IsGood := false;
                exit(IsGood);
            end;

        if IsBlankOrEmptyCondition(AcceptableValue) then
            if TestValue <> '' then begin
                IsGood := true;
                if AdjustTestValueIfGood then
                    TestValue := CopyStr(Format(ValueAsDate, 0, 9), 1, MaxStrLen(TestValue));

                exit(IsGood);
            end else begin
                IsGood := true;
                exit(IsGood);
            end;

        TempDateLookupBuffer."Period Start" := ValueAsDate;
        TempDateLookupBuffer.Insert();
        TempDateLookupBuffer.SetFilter("Period Start", AcceptableValue);
        IsGood := not TempDateLookupBuffer.IsEmpty();
        if IsGood and AdjustTestValueIfGood then
            TestValue := CopyStr(Format(ValueAsDate, 0, 9), 1, MaxStrLen(TestValue));

        exit(IsGood);
    end;

    internal procedure TestValueString(TestValue: Text; AcceptableValue: Text): Boolean
    var
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
    begin
        exit(TestValueString(TestValue, AcceptableValue, QltyCaseSensitivity::Sensitive));
    end;

    internal procedure TestValueString(TestValue: Text; AcceptableValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Boolean
    var
        TempTestStringValueQltyField: Record "Qlty. Field" temporary;
    begin
        if IsAnythingExceptEmptyCondition(AcceptableValue) then
            exit(TestValue <> '');

        if QltyCaseSensitivity = QltyCaseSensitivity::Insensitive then begin
            TempTestStringValueQltyField."Allowable Values" := CopyStr(TestValue.ToLower(), 1, MaxStrLen(TempTestStringValueQltyField."Allowable Values"));
            AcceptableValue := AcceptableValue.ToLower();
        end else
            TempTestStringValueQltyField."Allowable Values" := CopyStr(TestValue, 1, MaxStrLen(TempTestStringValueQltyField."Allowable Values"));

        TempTestStringValueQltyField.Insert();
        TempTestStringValueQltyField.SetFilter("Allowable Values", AcceptableValue);
        exit(not TempTestStringValueQltyField.IsEmpty());
    end;

    /// <summary>
    /// OnBeforeEvaluateGrade gives an opportunity to change how a grade is evaluated.
    /// </summary>
    /// <param name="TestQltyIGradeConditionConf">var Record "Qlty. Grade Condition Config".</param>
    /// <param name="FieldType">var Rnum "Qlty. Field Type".</param>
    /// <param name="TestValue">var Text.</param>
    /// <param name="OutCode">The grade.</param>
    /// <param name="Handled">Set to true to replace the default behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateGrade(var TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf."; var QltyFieldType: Enum "Qlty. Field Type"; var TestValue: Text; var Result: Code[20]; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterEvaluateGrade gives an opportunity to run additional logic after a grade has been determined by the system.
    /// </summary>
    /// <param name="TestQltyIGradeConditionConf">var Record "Qlty. Grade Condition Config".</param>
    /// <param name="FieldType">var Enum "Qlty. Field Type".</param>
    /// <param name="TestValue">var Text.</param>
    /// <param name="Result">var Code[20].</param>
    /// <param name="TempHighestQltyIGradeConditionConf">var Record "Qlty. I. Grade Condition Conf." temporary.</param>
    /// <param name="Handled">Set to true to replace the default behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterEvaluateGrade(var TestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf."; var QltyFieldType: Enum "Qlty. Field Type"; var TestValue: Text; var Result: Code[20]; var TempHighestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf." temporary; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Allows you to alter the behavior of validating allowable values on text.
    /// </summary>
    /// <param name="FieldNameForError"></param>
    /// <param name="TextToValidate"></param>
    /// <param name="AllowableValues"></param>
    /// <param name="FieldType"></param>
    /// <param name="TempBufferQltyLookupCode"></param>
    /// <param name="CaseOption"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAllowableValuesOnText(var FieldNameForError: Text; var TextToValidate: Text[250]; var AllowableValues: Text; var QltyFieldType: Enum "Qlty. Field Type"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary; var QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides the opportunity to extend and add additional validation after the allowable values has occurred.
    /// </summary>
    /// <param name="FieldNameForError"></param>
    /// <param name="TextToValidate"></param>
    /// <param name="AllowableValues"></param>
    /// <param name="FieldType"></param>
    /// <param name="TempBufferQltyLookupCode"></param>
    /// <param name="CaseOption"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAllowableValuesOnText(var FieldNameForError: Text; var TextToValidate: Text[250]; var AllowableValues: Text; var QltyFieldType: Enum "Qlty. Field Type"; var TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary; var QltyCaseSensitivity: Enum "Qlty. Case Sensitivity")
    begin
    end;
}
