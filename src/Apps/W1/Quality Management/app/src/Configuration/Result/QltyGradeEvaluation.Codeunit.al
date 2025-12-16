// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

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
    TableNo = "Qlty. Inspection Line";

    var
        IsDefaultNumberTok: Label '<>0', Locked = true;
        IsDefaultTextTok: Label '<>''''', Locked = true;
        InvalidDataTypeErr: Label 'The value "%1" is not allowed for %2, it is not a %3.', Comment = '%1=the value, %2=field name,%3=field type.';
        NotInAllowableValuesErr: Label 'The value "%1" is not allowed for %2, it must be in the range of "%3".', Comment = '%1=the value, %2=field name,%3=field type.';

    trigger OnRun()
    var
        OptionalQltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        if (not Rec.IsTemporary()) and (Rec."Inspection No." <> '') then
            OptionalQltyInspectionHeader.Get(Rec."Inspection No.", Rec."Reinspection No.");
        ValidateQltyInspectionLine(Rec, OptionalQltyInspectionHeader, true);
    end;

    /// <summary>
    /// Evaluates a grade with an optional test.
    /// The test is used to help with expression evaluation.
    /// </summary>
    /// <param name="OptionalQltyInspectionHeader"></param>
    /// <param name="QltyIGradeConditionConf"></param>
    /// <param name="QltyFieldType"></param>
    /// <param name="TestValue"></param>
    /// <param name="CaseOption"></param>
    /// <returns></returns>
    internal procedure EvaluateGrade(var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyFieldType: Enum "Qlty. Field Type"; TestValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Code[20]
    var
        TempNotUsedOptionalQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        exit(EvaluateGrade(OptionalQltyInspectionHeader, TempNotUsedOptionalQltyInspectionLine, QltyIGradeConditionConf, QltyFieldType, TestValue, QltyCaseSensitivity));
    end;

    /// <summary>
    /// Evaluates a grade with an optional test and inspection line.
    /// The test is used to help with expression evaluation.
    /// </summary>
    /// <param name="OptionalQltyInspectionHeader"></param>
    /// <param name="QltyIGradeConditionConf"></param>
    /// <param name="QltyFieldType"></param>
    /// <param name="TestValue"></param>
    /// <param name="CaseOption"></param>
    /// <returns></returns>
    procedure EvaluateGrade(var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalQltyInspectionLine: Record "Qlty. Inspection Line"; var QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf."; QltyFieldType: Enum "Qlty. Field Type"; TestValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity") Result: Code[20]
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
        OnBeforeEvaluateGrade(QltyIGradeConditionConf, QltyFieldType, TestValue, Result, Handled);
        if Handled then
            exit;

        QltyInspectionGrade.SetCurrentKey("Evaluation Sequence");
        QltyInspectionGrade.Ascending();
        if not QltyInspectionGrade.FindSet() then
            exit;

        repeat
            QltyIGradeConditionConf.SetRange("Grade Code", QltyInspectionGrade.Code);
            if QltyIGradeConditionConf.FindSet() then
                repeat
                    LoopConditionMet := false;

                    Condition := QltyIGradeConditionConf.Condition;
                    if Condition.Contains('[') then
                        Condition := QltyExpressionMgmt.EvaluateTextExpression(Condition, OptionalQltyInspectionHeader, OptionalQltyInspectionLine);

                    case QltyFieldType of
                        QltyFieldType::"Field Type Decimal":
                            LoopConditionMet := CheckIfValueIsDecimal(TestValue, Condition);
                        QltyFieldType::"Field Type Integer":
                            LoopConditionMet := CheckIfValueIsInteger(TestValue, Condition);
                        QltyFieldType::"Field Type Boolean":
                            if QltyMiscHelpers.CanTextBeInterpretedAsBooleanIsh(TestValue) and
                               QltyMiscHelpers.CanTextBeInterpretedAsBooleanIsh(Condition)
                            then
                                LoopConditionMet := QltyMiscHelpers.GetBooleanFor(TestValue) = QltyMiscHelpers.GetBooleanFor(Condition)
                            else
                                LoopConditionMet := CheckIfValueIsString(TestValue, Condition, QltyCaseSensitivity);
                        QltyFieldType::"Field Type Text", QltyFieldType::"Field Type Option", QltyFieldType::"Field Type Table Lookup", QltyFieldType::"Field Type Text Expression":
                            LoopConditionMet := CheckIfValueIsString(TestValue, Condition, QltyCaseSensitivity);
                        QltyFieldType::"Field Type Date":
                            begin
                                Small := CopyStr(TestValue, 1, MaxStrLen(Small));
                                LoopConditionMet := CheckIfValueIsDate(Small, Condition, false);
                                TestValue := Small;
                            end;
                        QltyFieldType::"Field Type DateTime":
                            begin
                                Small := CopyStr(TestValue, 1, MaxStrLen(Small));
                                LoopConditionMet := CheckIfValueIsDateTime(Small, Condition, false);
                                TestValue := Small;
                            end;
                        QltyFieldType::"Field Type Label":
                            LoopConditionMet := true;
                    end;
                    if LoopConditionMet then begin
                        AnyConditionMet := true;
                        TempHighestQltyIGradeConditionConf := QltyIGradeConditionConf;
                    end;
                until QltyIGradeConditionConf.Next() = 0;

        until QltyInspectionGrade.Next() = 0;

        OnAfterEvaluateGrade(QltyIGradeConditionConf, QltyFieldType, TestValue, Result, TempHighestQltyIGradeConditionConf, Handled);
        if Handled then
            exit;

        if AnyConditionMet then
            exit(TempHighestQltyIGradeConditionConf."Grade Code");
    end;

    /// <summary>
    /// Call this procedure to validate the inspection line.
    /// </summary>
    /// <param name="QltyInspectionLine"></param>
    internal procedure ValidateQltyInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        OptionalQltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        if (not QltyInspectionLine.IsTemporary()) and (QltyInspectionLine."Inspection No." <> '') then
            if OptionalQltyInspectionHeader.Get(QltyInspectionLine."Inspection No.", QltyInspectionLine."Reinspection No.") then;
        ValidateQltyInspectionLine(QltyInspectionLine, OptionalQltyInspectionHeader, true);
    end;

    /// <summary>
    /// This will *not* modify the inspection line.
    /// This will only try and validate the inspection line itself.
    /// </summary>
    /// <param name="QltyInspectionLine"></param>
    /// <param name="OptionalQltyInspectionHeader"></param>
    /// <returns></returns>
    [TryFunction]
    procedure TryValidateQltyInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        ValidateQltyInspectionLine(QltyInspectionLine, OptionalQltyInspectionHeader, false);
    end;

    /// <summary>
    /// Call this procedure to validate the inspection line for the given test.
    /// </summary>
    /// <param name="QltyInspectionLine"></param>
    /// <param name="OptionalQltyInspectionHeader"></param>
    /// <param name="Modify">Set to true to modify the grade(default), false to avoid modifying.</param>
    procedure ValidateQltyInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; Modify: Boolean)
    begin
        ValidateInspectionLineWithAllowableValues(QltyInspectionLine, OptionalQltyInspectionHeader, true, Modify);
    end;

    procedure ValidateInspectionLineWithAllowableValues(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; CheckForAllowableValues: Boolean; Modify: Boolean)
    var
        QltyField: Record "Qlty. Field";
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        Grade: Code[20];
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
    begin
        QltyInspectionLine.CalcFields("Field Type");

        if CheckForAllowableValues then
            ValidateAllowableValuesOnInspectionLine(QltyInspectionLine, OptionalQltyInspectionHeader);

        GetTestGradeConditionConfigFilters(QltyInspectionLine, QltyIGradeConditionConf);

        QltyCaseSensitivity := QltyCaseSensitivity::Sensitive;
        if QltyField.Get(QltyInspectionLine."Field Code") then
            QltyCaseSensitivity := QltyField."Case Sensitive";

        Grade := EvaluateGrade(OptionalQltyInspectionHeader, QltyInspectionLine, QltyIGradeConditionConf, QltyInspectionLine."Field Type", QltyInspectionLine."Test Value", QltyCaseSensitivity);

        QltyInspectionLine."Failure State" := QltyInspectionLine."Failure State"::" ";
        if Grade <> '' then begin
            QltyInspectionGrade.Get(Grade);
            if QltyInspectionGrade."Grade Category" = QltyInspectionGrade."Grade Category"::"Not acceptable" then
                QltyInspectionLine."Failure State" := QltyInspectionLine."Failure State"::"Failed from Acceptance Criteria";
        end;

        QltyInspectionLine.Validate("Grade Code", Grade);

        if Modify then
            QltyInspectionLine.Modify(true);

        if (not QltyInspectionLine.IsTemporary()) and (OptionalQltyInspectionHeader."No." <> '') and (QltyInspectionLine."Inspection No." <> '') then begin
            OptionalQltyInspectionHeader.UpdateGradeFromLines();
            OptionalQltyInspectionHeader.Validate("Grade Code");
            if Modify then
                if OptionalQltyInspectionHeader.Modify(true) then;
        end;
    end;

    procedure GetInspectionLineConfigFilters(var QltyInspectionLine: Record "Qlty. Inspection Line"; var TemplateLineQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.")
    begin
        TemplateLineQltyIGradeConditionConf.SetRange("Condition Type", TemplateLineQltyIGradeConditionConf."Condition Type"::Inspection);
        TemplateLineQltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TemplateLineQltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        TemplateLineQltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TemplateLineQltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");
    end;

    local procedure GetTestGradeConditionConfigFilters(var QltyInspectionLine: Record "Qlty. Inspection Line"; var QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.")
    begin
        QltyIGradeConditionConf.Reset();
        QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Inspection);
        QltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIGradeConditionConf.SetRange("Target Reinspection No.", QltyInspectionLine."Reinspection No.");
        QltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");

        if QltyIGradeConditionConf.IsEmpty() then begin
            QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Template);
            QltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Template Code");
            QltyIGradeConditionConf.SetRange("Target Reinspection No.");
            QltyIGradeConditionConf.SetRange("Target Line No.", QltyInspectionLine."Template Line No.");
            QltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");
            if QltyIGradeConditionConf.IsEmpty() then begin
                QltyIGradeConditionConf.SetRange("Condition Type", QltyIGradeConditionConf."Condition Type"::Field);
                QltyIGradeConditionConf.SetRange("Target Code", QltyInspectionLine."Field Code");
                QltyIGradeConditionConf.SetRange("Target Reinspection No.");
                QltyIGradeConditionConf.SetRange("Target Line No.");
                QltyIGradeConditionConf.SetRange("Field Code", QltyInspectionLine."Field Code");
            end;
        end;
    end;

    local procedure ValidateAllowableValuesOnInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyField: Record "Qlty. Field";
        TempBufferQltyLookupCode: Record "Qlty. Lookup Code" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
        FieldNameForError: Text;
        AllowableValues: Text;
    begin
        QltyInspectionLine.CalcFields("Field Type");
        if QltyInspectionLine."Test Value" = '' then
            exit;

        if QltyInspectionLine.Description <> '' then
            FieldNameForError := QltyInspectionLine.Description
        else
            FieldNameForError := QltyInspectionLine."Field Code";

        if QltyInspectionLine."Field Type" in [QltyInspectionLine."Field Type"::"Field Type Option", QltyInspectionLine."Field Type"::"Field Type Table Lookup"] then
            QltyInspectionLine.CollectAllowableValues(TempBufferQltyLookupCode);

        QltyCaseSensitivity := QltyCaseSensitivity::Sensitive;
        if QltyField.Get(QltyInspectionLine."Field Code") then
            QltyCaseSensitivity := QltyField."Case Sensitive";

        if QltyInspectionLine.IsTemporary() and (QltyInspectionLine."Field Type" in [QltyInspectionLine."Field Type"::"Field Type Option", QltyInspectionLine."Field Type"::"Field Type Table Lookup"]) then
            QltyCaseSensitivity := QltyCaseSensitivity::Insensitive;

        AllowableValues := QltyInspectionLine."Allowable Values";
        if AllowableValues.Contains('[') then
            AllowableValues := QltyExpressionMgmt.EvaluateTextExpression(AllowableValues, OptionalQltyInspectionHeader, QltyInspectionLine);

        ValidateAllowableValuesOnText(
            FieldNameForError,
            QltyInspectionLine."Test Value",
            AllowableValues,
            QltyInspectionLine."Field Type",
            TempBufferQltyLookupCode,
            QltyCaseSensitivity);
    end;

    procedure ValidateAllowableValuesOnField(var QltyField: Record "Qlty. Field")
    var
        TempDummyQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempDummyQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        ValidateAllowableValuesOnField(QltyField, TempDummyQltyInspectionHeader, TempDummyQltyInspectionLine);
    end;

    internal procedure ValidateAllowableValuesOnField(var QltyField: Record "Qlty. Field"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        TempDummyQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        ValidateAllowableValuesOnField(QltyField, OptionalContextQltyInspectionHeader, TempDummyQltyInspectionLine);
    end;

    procedure ValidateAllowableValuesOnField(var QltyField: Record "Qlty. Field"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalContextQltyInspectionLine: Record "Qlty. Inspection Line")
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
            QltyField.CollectAllowableValues(OptionalContextQltyInspectionHeader, OptionalContextQltyInspectionLine, TempBufferQltyLookupCode, QltyField."Default Value");

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

                    if not QltyGradeEvaluation.CheckIfValueIsDecimal(TextToValidate, AllowableValues) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                end;
            QltyFieldType::"Field Type Integer":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(ValueAsInteger, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);

                    if not QltyGradeEvaluation.CheckIfValueIsInteger(TextToValidate, AllowableValues) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, AllowableValues);
                end;
            QltyFieldType::"Field Type DateTime":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(DateAndTimeValue, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);
                    if not QltyGradeEvaluation.CheckIfValueIsDateTime(TextToValidate, AllowableValues, true) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);
                end;
            QltyFieldType::"Field Type Date":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(DateOnlyValue, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfFieldNameForError, QltyFieldType);

                    if not QltyGradeEvaluation.CheckIfValueIsDate(TextToValidate, AllowableValues, true) then
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
                    if not QltyGradeEvaluation.CheckIfValueIsString(TextToValidate, ConvertStr(AllowableValues, ',', '|'), QltyCaseSensitivity) then
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

    internal procedure CheckIfValueIsDecimal(ValueToCheck: Text; AcceptableValue: Text): Boolean
    var
        TempNumericalQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
        ValueAsDecimal: Decimal;
    begin
        if ValueToCheck = '' then
            ValueAsDecimal := 0
        else
            Evaluate(ValueAsDecimal, ValueToCheck);

        if (AcceptableValue = '') and (ValueToCheck <> '') then
            exit(true);

        if AcceptableValue = '<>''''' then
            AcceptableValue := '<>0';

        if (ValueToCheck = '') and not (AcceptableValue in ['', '=''''', '<>0']) then
            exit(false);

        TempNumericalQltyInspectionLine."Numeric Value" := ValueAsDecimal;
        if TempNumericalQltyInspectionLine.Insert(false) then;
        TempNumericalQltyInspectionLine.SetFilter("Numeric Value", AcceptableValue);
        exit(not TempNumericalQltyInspectionLine.IsEmpty());
    end;

    internal procedure CheckIfValueIsInteger(ValueToCheck: Text; AcceptableValue: Text): Boolean
    var
        TempInteger: Record "Integer" temporary;
        ValueAsInteger: Integer;
    begin
        if ValueToCheck = '' then
            ValueAsInteger := 0
        else
            Evaluate(ValueAsInteger, ValueToCheck);

        if (AcceptableValue = '') and (ValueToCheck <> '') then
            exit(true);

        if AcceptableValue = '<>''''' then
            AcceptableValue := '<>0';

        if (ValueToCheck = '') and not (AcceptableValue in ['', '=''''', '<>0']) then
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

    procedure CheckIfValueIsDateTime(var ValueToCheck: Text[250]; AcceptableValue: Text; AdjustValueIfGood: Boolean) IsGood: Boolean
    var
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        ValueAsDateTime: DateTime;
    begin
        if ValueToCheck = '' then
            ValueAsDateTime := 0DT
        else
            Evaluate(ValueAsDateTime, ValueToCheck);

        if IsAnythingExceptEmptyCondition(AcceptableValue) then
            if ValueToCheck <> '' then begin
                IsGood := true;
                if AdjustValueIfGood then
                    ValueToCheck := CopyStr(Format(ValueAsDateTime, 0, 9), 1, MaxStrLen(ValueToCheck));

                exit(IsGood);
            end else begin
                IsGood := false;
                exit(IsGood);
            end;

        if IsBlankOrEmptyCondition(AcceptableValue) then
            if ValueToCheck <> '' then begin
                IsGood := true;
                if AdjustValueIfGood then
                    ValueToCheck := CopyStr(Format(ValueAsDateTime, 0, 9), 1, MaxStrLen(ValueToCheck));

                exit(IsGood);
            end else begin
                IsGood := true;
                exit(IsGood);
            end;

        TempQltyInspectionHeader."Finished Date" := ValueAsDateTime;
        TempQltyInspectionHeader.Insert();
        TempQltyInspectionHeader.SetFilter("Finished Date", AcceptableValue);
        IsGood := not TempQltyInspectionHeader.IsEmpty();
        if IsGood and AdjustValueIfGood then
            ValueToCheck := CopyStr(Format(ValueAsDateTime, 0, 9), 1, MaxStrLen(ValueToCheck));

        exit(IsGood);
    end;

    procedure CheckIfValueIsDate(var ValueToCheck: Text[250]; AcceptableValue: Text; AdjustValueIfGood: Boolean) IsGood: Boolean
    var
        TempDateLookupBuffer: Record "Date Lookup Buffer" temporary;
        ValueAsDate: Date;
    begin
        if ValueToCheck = '' then
            ValueAsDate := 0D
        else
            Evaluate(ValueAsDate, ValueToCheck);

        if IsAnythingExceptEmptyCondition(AcceptableValue) then
            if ValueToCheck <> '' then begin
                IsGood := true;
                if AdjustValueIfGood then
                    ValueToCheck := CopyStr(Format(ValueAsDate, 0, 9), 1, MaxStrLen(ValueToCheck));

                exit(IsGood);
            end else begin
                IsGood := false;
                exit(IsGood);
            end;

        if IsBlankOrEmptyCondition(AcceptableValue) then
            if ValueToCheck <> '' then begin
                IsGood := true;
                if AdjustValueIfGood then
                    ValueToCheck := CopyStr(Format(ValueAsDate, 0, 9), 1, MaxStrLen(ValueToCheck));

                exit(IsGood);
            end else begin
                IsGood := true;
                exit(IsGood);
            end;

        TempDateLookupBuffer."Period Start" := ValueAsDate;
        TempDateLookupBuffer.Insert();
        TempDateLookupBuffer.SetFilter("Period Start", AcceptableValue);
        IsGood := not TempDateLookupBuffer.IsEmpty();
        if IsGood and AdjustValueIfGood then
            ValueToCheck := CopyStr(Format(ValueAsDate, 0, 9), 1, MaxStrLen(ValueToCheck));

        exit(IsGood);
    end;

    internal procedure CheckIfValueIsString(ValueToCheck: Text; AcceptableValue: Text): Boolean
    var
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
    begin
        exit(CheckIfValueIsString(ValueToCheck, AcceptableValue, QltyCaseSensitivity::Sensitive));
    end;

    internal procedure CheckIfValueIsString(ValueToCheck: Text; AcceptableValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Boolean
    var
        TempTestStringValueQltyField: Record "Qlty. Field" temporary;
    begin
        if IsAnythingExceptEmptyCondition(AcceptableValue) then
            exit(ValueToCheck <> '');

        if QltyCaseSensitivity = QltyCaseSensitivity::Insensitive then begin
            TempTestStringValueQltyField."Allowable Values" := CopyStr(ValueToCheck.ToLower(), 1, MaxStrLen(TempTestStringValueQltyField."Allowable Values"));
            AcceptableValue := AcceptableValue.ToLower();
        end else
            TempTestStringValueQltyField."Allowable Values" := CopyStr(ValueToCheck, 1, MaxStrLen(TempTestStringValueQltyField."Allowable Values"));

        TempTestStringValueQltyField.Insert();
        TempTestStringValueQltyField.SetFilter("Allowable Values", AcceptableValue);
        exit(not TempTestStringValueQltyField.IsEmpty());
    end;

    /// <summary>
    /// OnBeforeEvaluateGrade gives an opportunity to change how a grade is evaluated.
    /// </summary>
    /// <param name="QltyIGradeConditionConf">var Record "Qlty. Grade Condition Config".</param>
    /// <param name="FieldType">var Rnum "Qlty. Field Type".</param>
    /// <param name="TestValue">var Text.</param>
    /// <param name="OutCode">The grade.</param>
    /// <param name="Handled">Set to true to replace the default behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateGrade(var QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf."; var QltyFieldType: Enum "Qlty. Field Type"; var TestValue: Text; var Result: Code[20]; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterEvaluateGrade gives an opportunity to run additional logic after a grade has been determined by the system.
    /// </summary>
    /// <param name="QltyIGradeConditionConf">var Record "Qlty. Grade Condition Config".</param>
    /// <param name="FieldType">var Enum "Qlty. Field Type".</param>
    /// <param name="TestValue">var Text.</param>
    /// <param name="Result">var Code[20].</param>
    /// <param name="TempHighestQltyIGradeConditionConf">var Record "Qlty. I. Grade Condition Conf." temporary.</param>
    /// <param name="Handled">Set to true to replace the default behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterEvaluateGrade(var QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf."; var QltyFieldType: Enum "Qlty. Field Type"; var TestValue: Text; var Result: Code[20]; var TempHighestQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf." temporary; var Handled: Boolean)
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
