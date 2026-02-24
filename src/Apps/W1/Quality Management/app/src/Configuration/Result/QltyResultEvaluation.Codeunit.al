// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using System.DateTime;
using System.Utilities;

/// <summary>
/// Methods to help with result evaluation.
/// </summary>
codeunit 20410 "Qlty. Result Evaluation"
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
            OptionalQltyInspectionHeader.Get(Rec."Inspection No.", Rec."Re-inspection No.");
        ValidateQltyInspectionLine(Rec, OptionalQltyInspectionHeader, true);
    end;

    /// <summary>
    /// Evaluates a result with an optional test.
    /// The test is used to help with expression evaluation.
    /// </summary>
    /// <param name="OptionalQltyInspectionHeader"></param>
    /// <param name="QltyIResultConditConf"></param>
    /// <param name="QltyTestValueType"></param>
    /// <param name="TestValue"></param>
    /// <param name="CaseOption"></param>
    /// <returns></returns>
    internal procedure EvaluateResult(var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyTestValueType: Enum "Qlty. Test Value Type"; TestValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Code[20]
    var
        TempNotUsedOptionalQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        exit(EvaluateResult(OptionalQltyInspectionHeader, TempNotUsedOptionalQltyInspectionLine, QltyIResultConditConf, QltyTestValueType, TestValue, QltyCaseSensitivity));
    end;

    /// <summary>
    /// Evaluates a result with an optional test and inspection line.
    /// The test is used to help with expression evaluation.
    /// </summary>
    /// <param name="OptionalQltyInspectionHeader"></param>
    /// <param name="QltyIResultConditConf"></param>
    /// <param name="QltyTestValueType"></param>
    /// <param name="TestValue"></param>
    /// <param name="CaseOption"></param>
    /// <returns></returns>
    internal procedure EvaluateResult(var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalQltyInspectionLine: Record "Qlty. Inspection Line"; var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf."; QltyTestValueType: Enum "Qlty. Test Value Type"; TestValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity") Result: Code[20]
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        TempHighestQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf." temporary;
        QltyBooleanParsing: Codeunit "Qlty. Boolean Parsing";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        LoopConditionMet: Boolean;
        AnyConditionMet: Boolean;
        IsHandled: Boolean;
        Small: Text[250];
        Condition: Text;
    begin
        OnBeforeEvaluateResult(QltyIResultConditConf, QltyTestValueType, TestValue, Result, IsHandled);
        if IsHandled then
            exit;

        QltyInspectionResult.SetCurrentKey("Evaluation Sequence");
        QltyInspectionResult.Ascending();
        if not QltyInspectionResult.FindSet() then
            exit;

        repeat
            QltyIResultConditConf.SetRange("Result Code", QltyInspectionResult.Code);
            if QltyIResultConditConf.FindSet() then
                repeat
                    LoopConditionMet := false;

                    Condition := QltyIResultConditConf.Condition;
                    if Condition.Contains('[') then
                        Condition := QltyExpressionMgmt.EvaluateTextExpression(Condition, OptionalQltyInspectionHeader, OptionalQltyInspectionLine);

                    case QltyTestValueType of
                        QltyTestValueType::"Value Type Decimal":
                            LoopConditionMet := CheckIfValueIsDecimal(TestValue, Condition);
                        QltyTestValueType::"Value Type Integer":
                            LoopConditionMet := CheckIfValueIsInteger(TestValue, Condition);
                        QltyTestValueType::"Value Type Boolean":
                            if QltyBooleanParsing.CanTextBeInterpretedAsBooleanIsh(TestValue) and
                               QltyBooleanParsing.CanTextBeInterpretedAsBooleanIsh(Condition)
                            then
                                LoopConditionMet := QltyBooleanParsing.GetBooleanFor(TestValue) = QltyBooleanParsing.GetBooleanFor(Condition)
                            else
                                LoopConditionMet := CheckIfValueIsString(TestValue, Condition, QltyCaseSensitivity);
                        QltyTestValueType::"Value Type Text", QltyTestValueType::"Value Type Option", QltyTestValueType::"Value Type Table Lookup", QltyTestValueType::"Value Type Text Expression":
                            LoopConditionMet := CheckIfValueIsString(TestValue, Condition, QltyCaseSensitivity);
                        QltyTestValueType::"Value Type Date":
                            begin
                                Small := CopyStr(TestValue, 1, MaxStrLen(Small));
                                LoopConditionMet := CheckIfValueIsDate(Small, Condition, false);
                                TestValue := Small;
                            end;
                        QltyTestValueType::"Value Type DateTime":
                            begin
                                Small := CopyStr(TestValue, 1, MaxStrLen(Small));
                                LoopConditionMet := CheckIfValueIsDateTime(Small, Condition, false);
                                TestValue := Small;
                            end;
                        QltyTestValueType::"Value Type Label":
                            LoopConditionMet := true;
                    end;
                    if LoopConditionMet then begin
                        AnyConditionMet := true;
                        TempHighestQltyIResultConditConf := QltyIResultConditConf;
                    end;
                until QltyIResultConditConf.Next() = 0;

        until QltyInspectionResult.Next() = 0;

        OnAfterEvaluateResult(QltyIResultConditConf, QltyTestValueType, TestValue, Result, TempHighestQltyIResultConditConf);

        if AnyConditionMet then
            exit(TempHighestQltyIResultConditConf."Result Code");
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
            if OptionalQltyInspectionHeader.Get(QltyInspectionLine."Inspection No.", QltyInspectionLine."Re-inspection No.") then;
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
    internal procedure TryValidateQltyInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        ValidateQltyInspectionLine(QltyInspectionLine, OptionalQltyInspectionHeader, false);
    end;

    /// <summary>
    /// Call this procedure to validate the inspection line for the given test.
    /// </summary>
    /// <param name="QltyInspectionLine"></param>
    /// <param name="OptionalQltyInspectionHeader"></param>
    /// <param name="Modify">Set to true to modify the result(default), false to avoid modifying.</param>
    procedure ValidateQltyInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; Modify: Boolean)
    begin
        ValidateInspectionLineWithAllowableValues(QltyInspectionLine, OptionalQltyInspectionHeader, true, Modify);
    end;

    internal procedure ValidateInspectionLineWithAllowableValues(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; CheckForAllowableValues: Boolean; UpdateHeader: Boolean)
    var
        QltyTest: Record "Qlty. Test";
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Result: Code[20];
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
    begin
        QltyInspectionLine.CalcFields("Test Value Type");

        if CheckForAllowableValues then
            ValidateAllowableValuesOnInspectionLine(QltyInspectionLine, OptionalQltyInspectionHeader);

        GetTestResultConditionConfigFilters(QltyInspectionLine, QltyIResultConditConf);

        QltyCaseSensitivity := QltyCaseSensitivity::Sensitive;
        if QltyTest.Get(QltyInspectionLine."Test Code") then
            QltyCaseSensitivity := QltyTest."Case Sensitive";

        Result := EvaluateResult(OptionalQltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, QltyInspectionLine."Test Value Type", QltyInspectionLine."Test Value", QltyCaseSensitivity);

        QltyInspectionLine."Failure State" := QltyInspectionLine."Failure State"::" ";
        if Result <> '' then begin
            QltyInspectionResult.Get(Result);
            if QltyInspectionResult."Result Category" = QltyInspectionResult."Result Category"::"Not acceptable" then
                QltyInspectionLine."Failure State" := QltyInspectionLine."Failure State"::"Failed from Acceptance Criteria";
        end;

        QltyInspectionLine.Validate("Result Code", Result);

        if UpdateHeader then
            QltyInspectionLine.Modify(true);

        if (not QltyInspectionLine.IsTemporary()) and (OptionalQltyInspectionHeader."No." <> '') and (QltyInspectionLine."Inspection No." <> '') then begin
            OptionalQltyInspectionHeader.UpdateResultFromLines();
            OptionalQltyInspectionHeader.Validate("Result Code");
            if UpdateHeader and not IsNullGuid(OptionalQltyInspectionHeader.SystemId) then
                if OptionalQltyInspectionHeader.Modify(true) then;
        end;
    end;

    internal procedure GetInspectionLineConfigFilters(var QltyInspectionLine: Record "Qlty. Inspection Line"; var TemplateLineQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.")
    begin
        TemplateLineQltyIResultConditConf.SetRange("Condition Type", TemplateLineQltyIResultConditConf."Condition Type"::Inspection);
        TemplateLineQltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        TemplateLineQltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        TemplateLineQltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        TemplateLineQltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");
    end;

    local procedure GetTestResultConditionConfigFilters(var QltyInspectionLine: Record "Qlty. Inspection Line"; var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.")
    begin
        QltyIResultConditConf.Reset();
        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Inspection No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", QltyInspectionLine."Re-inspection No.");
        QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Line No.");
        QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");

        if QltyIResultConditConf.IsEmpty() then begin
            QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Template);
            QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Template Code");
            QltyIResultConditConf.SetRange("Target Re-inspection No.");
            QltyIResultConditConf.SetRange("Target Line No.", QltyInspectionLine."Template Line No.");
            QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");
            if QltyIResultConditConf.IsEmpty() then begin
                QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Test);
                QltyIResultConditConf.SetRange("Target Code", QltyInspectionLine."Test Code");
                QltyIResultConditConf.SetRange("Target Re-inspection No.");
                QltyIResultConditConf.SetRange("Target Line No.");
                QltyIResultConditConf.SetRange("Test Code", QltyInspectionLine."Test Code");
            end;
        end;
    end;

    local procedure ValidateAllowableValuesOnInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyTest: Record "Qlty. Test";
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
        TestNameForError: Text;
        AllowableValues: Text;
    begin
        QltyInspectionLine.CalcFields("Test Value Type");
        if QltyInspectionLine."Test Value" = '' then
            exit;

        if QltyInspectionLine.Description <> '' then
            TestNameForError := QltyInspectionLine.Description
        else
            TestNameForError := QltyInspectionLine."Test Code";

        if QltyInspectionLine."Test Value Type" in [QltyInspectionLine."Test Value Type"::"Value Type Option", QltyInspectionLine."Test Value Type"::"Value Type Table Lookup"] then
            QltyInspectionLine.CollectAllowableValues(TempBufferQltyTestLookupValue);

        QltyCaseSensitivity := QltyCaseSensitivity::Sensitive;
        if QltyTest.Get(QltyInspectionLine."Test Code") then
            QltyCaseSensitivity := QltyTest."Case Sensitive";

        if QltyInspectionLine.IsTemporary() and (QltyInspectionLine."Test Value Type" in [QltyInspectionLine."Test Value Type"::"Value Type Option", QltyInspectionLine."Test Value Type"::"Value Type Table Lookup"]) then
            QltyCaseSensitivity := QltyCaseSensitivity::Insensitive;

        AllowableValues := QltyInspectionLine."Allowable Values";
        if AllowableValues.Contains('[') then
            AllowableValues := QltyExpressionMgmt.EvaluateTextExpression(AllowableValues, OptionalQltyInspectionHeader, QltyInspectionLine);

        ValidateAllowableValuesOnText(
            TestNameForError,
            QltyInspectionLine."Test Value",
            AllowableValues,
            QltyInspectionLine."Test Value Type",
            TempBufferQltyTestLookupValue,
            QltyCaseSensitivity);
    end;

    internal procedure ValidateAllowableValuesOnTest(var QltyTest: Record "Qlty. Test")
    var
        TempDummyQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempDummyQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        ValidateAllowableValuesOnTest(QltyTest, TempDummyQltyInspectionHeader, TempDummyQltyInspectionLine);
    end;

    internal procedure ValidateAllowableValuesOnTest(var QltyTest: Record "Qlty. Test"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        TempDummyQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        ValidateAllowableValuesOnTest(QltyTest, OptionalContextQltyInspectionHeader, TempDummyQltyInspectionLine);
    end;

    internal procedure ValidateAllowableValuesOnTest(var QltyTest: Record "Qlty. Test"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalContextQltyInspectionLine: Record "Qlty. Inspection Line")
    var
        TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary;
        QltyCaseSensitivity: Enum "Qlty. Case Sensitivity";
        TestNameForError: Text;
    begin
        if QltyTest.Description <> '' then
            TestNameForError := QltyTest.Description
        else
            TestNameForError := QltyTest.Code;

        if QltyTest."Test Value Type" in [QltyTest."Test Value Type"::"Value Type Option", QltyTest."Test Value Type"::"Value Type Table Lookup"] then
            QltyTest.CollectAllowableValues(OptionalContextQltyInspectionHeader, OptionalContextQltyInspectionLine, TempBufferQltyTestLookupValue, QltyTest."Default Value");

        QltyCaseSensitivity := QltyTest."Case Sensitive";

        if QltyTest.IsTemporary() and (QltyTest."Test Value Type" in [QltyTest."Test Value Type"::"Value Type Option", QltyTest."Test Value Type"::"Value Type Table Lookup"]) then
            QltyCaseSensitivity := QltyCaseSensitivity::Insensitive;

        ValidateAllowableValuesOnText(TestNameForError, QltyTest."Default Value", QltyTest."Allowable Values", QltyTest."Test Value Type", TempBufferQltyTestLookupValue, QltyCaseSensitivity);
    end;

    local procedure ValidateAllowableValuesOnText(NumberOrNameOfTestNameForError: Text; var TextToValidate: Text[250]; AllowableValues: Text; QltyTestValueType: Enum "Qlty. Test Value Type"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity")
    var
        QltyBooleanParsing: Codeunit "Qlty. Boolean Parsing";
        QltyLocalization: Codeunit "Qlty. Localization";
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
        ValueAsDecimal: Decimal;
        ValueAsInteger: Integer;
        DateAndTimeValue: DateTime;
        DateOnlyValue: Date;
        IsHandled: Boolean;
    begin
        OnBeforeValidateAllowableValuesOnText(NumberOrNameOfTestNameForError, TextToValidate, AllowableValues, QltyTestValueType, TempBufferQltyTestLookupValue, QltyCaseSensitivity, IsHandled);
        if IsHandled then
            exit;

        if TextToValidate = '' then
            exit;

        case QltyTestValueType of
            QltyTestValueType::"Value Type Decimal":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(ValueAsDecimal, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfTestNameForError, QltyTestValueType);

                    if not QltyResultEvaluation.CheckIfValueIsDecimal(TextToValidate, AllowableValues) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, AllowableValues);
                end;
            QltyTestValueType::"Value Type Integer":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(ValueAsInteger, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfTestNameForError, QltyTestValueType);

                    if not QltyResultEvaluation.CheckIfValueIsInteger(TextToValidate, AllowableValues) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, AllowableValues);
                end;
            QltyTestValueType::"Value Type DateTime":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(DateAndTimeValue, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfTestNameForError, QltyTestValueType);
                    if not QltyResultEvaluation.CheckIfValueIsDateTime(TextToValidate, AllowableValues, true) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, QltyTestValueType);
                end;
            QltyTestValueType::"Value Type Date":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then begin
                    if (TextToValidate <> '') and (not Evaluate(DateOnlyValue, TextToValidate)) then
                        Error(InvalidDataTypeErr, TextToValidate, NumberOrNameOfTestNameForError, QltyTestValueType);

                    if not QltyResultEvaluation.CheckIfValueIsDate(TextToValidate, AllowableValues, true) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, AllowableValues);
                end;
            QltyTestValueType::"Value Type Boolean":
                begin
                    if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then
                        if QltyBooleanParsing.GetBooleanFor(TextToValidate) then
                            TextToValidate := QltyLocalization.GetTranslatedYes()
                        else
                            TextToValidate := QltyLocalization.GetTranslatedNo();

                    if (AllowableValues <> '') and (QltyBooleanParsing.CanTextBeInterpretedAsBooleanIsh(AllowableValues)) then begin
                        if not QltyBooleanParsing.GetBooleanFor(TextToValidate) = QltyBooleanParsing.GetBooleanFor(AllowableValues) then
                            Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, AllowableValues);
                    end else
                        if not (TextToValidate in [QltyLocalization.GetTranslatedYes(), QltyLocalization.GetTranslatedNo(), '']) then
                            Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, AllowableValues);
                end;
            QltyTestValueType::"Value Type Text":
                if not (IsBlankOrEmptyCondition(AllowableValues) and (TextToValidate = '')) then
                    if not QltyResultEvaluation.CheckIfValueIsString(TextToValidate, ConvertStr(AllowableValues, ',', '|'), QltyCaseSensitivity) then
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, AllowableValues);

            QltyTestValueType::"Value Type Option",
                QltyTestValueType::"Value Type Table Lookup":
                begin
                    TextToValidate := CopyStr(TextToValidate.Trim(), 1, MaxStrLen(TextToValidate));

                    TempBufferQltyTestLookupValue.Reset();
                    TempBufferQltyTestLookupValue.SetRange("Custom 1", TextToValidate);
                    if TempBufferQltyTestLookupValue.IsEmpty() and (QltyCaseSensitivity = QltyCaseSensitivity::Insensitive) then begin
                        TempBufferQltyTestLookupValue.Reset();
                        TempBufferQltyTestLookupValue.SetRange("Custom 2", TextToValidate.ToLower());
                    end;
                    if TempBufferQltyTestLookupValue.IsEmpty() then begin
                        TempBufferQltyTestLookupValue.Reset();
                        if QltyCaseSensitivity = QltyCaseSensitivity::Insensitive then
                            TempBufferQltyTestLookupValue.SetFilter("Custom 2", '%1', '@' + TextToValidate.ToLower() + '*')
                        else
                            TempBufferQltyTestLookupValue.SetFilter("Custom 1", '%1', TextToValidate + '*');
                    end;
                    if TempBufferQltyTestLookupValue.Count() = 1 then begin
                        TempBufferQltyTestLookupValue.FindFirst();
                        TextToValidate := CopyStr(TempBufferQltyTestLookupValue."Custom 1", 1, MaxStrLen(TextToValidate));
                    end else
                        Error(NotInAllowableValuesErr, TextToValidate, NumberOrNameOfTestNameForError, AllowableValues);
                end;
        end;
        OnAfterValidateAllowableValuesOnText(NumberOrNameOfTestNameForError, TextToValidate, AllowableValues, QltyTestValueType, TempBufferQltyTestLookupValue, QltyCaseSensitivity);
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

        TempNumericalQltyInspectionLine."Derived Numeric Value" := ValueAsDecimal;
        if TempNumericalQltyInspectionLine.Insert(false) then;
        TempNumericalQltyInspectionLine.SetFilter("Derived Numeric Value", AcceptableValue);
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

    internal procedure CheckIfValueIsDateTime(var ValueToCheck: Text[250]; AcceptableValue: Text; AdjustValueIfGood: Boolean) IsGood: Boolean
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

    internal procedure CheckIfValueIsDate(var ValueToCheck: Text[250]; AcceptableValue: Text; AdjustValueIfGood: Boolean) IsGood: Boolean
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
        TempTestStringValueQltyTest: Record "Qlty. Test" temporary;
    begin
        if IsAnythingExceptEmptyCondition(AcceptableValue) then
            exit(ValueToCheck <> '');

        if QltyCaseSensitivity = QltyCaseSensitivity::Insensitive then begin
            TempTestStringValueQltyTest."Allowable Values" := CopyStr(ValueToCheck.ToLower(), 1, MaxStrLen(TempTestStringValueQltyTest."Allowable Values"));
            AcceptableValue := AcceptableValue.ToLower();
        end else
            TempTestStringValueQltyTest."Allowable Values" := CopyStr(ValueToCheck, 1, MaxStrLen(TempTestStringValueQltyTest."Allowable Values"));

        TempTestStringValueQltyTest.Insert();
        TempTestStringValueQltyTest.SetFilter("Allowable Values", AcceptableValue);
        exit(not TempTestStringValueQltyTest.IsEmpty());
    end;

    /// <summary>
    /// OnBeforeEvaluateResult gives an opportunity to change how a result is evaluated.
    /// </summary>
    /// <param name="QltyIResultConditConf">var Record "Qlty. Result Condition Config".</param>
    /// <param name="QltyTestValueType">var Rnum "Qlty. Test Value Type".</param>
    /// <param name="TestValue">var Text.</param>
    /// <param name="OutCode">The result.</param>
    /// <param name="IsHandled">Set to true to replace the default behavior.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateResult(var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf."; var QltyTestValueType: Enum "Qlty. Test Value Type"; var TestValue: Text; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterEvaluateResult gives an opportunity to run additional logic after a result has been determined by the system.
    /// </summary>
    /// <param name="QltyIResultConditConf">var Record "Qlty. Result Condition Config".</param>
    /// <param name="QltyTestValueType">var Enum "Qlty. Test Value Type".</param>
    /// <param name="TestValue">var Text.</param>
    /// <param name="Result">var Code[20].</param>
    /// <param name="TempHighestQltyIResultConditConf">var Record "Qlty. I. Result Condit. Conf." temporary.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterEvaluateResult(var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf."; var QltyTestValueType: Enum "Qlty. Test Value Type"; var TestValue: Text; var Result: Code[20]; var TempHighestQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf." temporary)
    begin
    end;

    /// <summary>
    /// Allows you to alter the behavior of validating allowable values on text.
    /// </summary>
    /// <param name="TestNameForError"></param>
    /// <param name="TextToValidate"></param>
    /// <param name="AllowableValues"></param>
    /// <param name="QltyTestValueType"></param>
    /// <param name="TempBufferQltyTestLookupValue"></param>
    /// <param name="CaseOption"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAllowableValuesOnText(var TestNameForError: Text; var TextToValidate: Text[250]; var AllowableValues: Text; var QltyTestValueType: Enum "Qlty. Test Value Type"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary; var QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides the opportunity to extend and add additional validation after the allowable values has occurred.
    /// </summary>
    /// <param name="TestNameForError"></param>
    /// <param name="TextToValidate"></param>
    /// <param name="AllowableValues"></param>
    /// <param name="QltyTestValueType"></param>
    /// <param name="TempBufferQltyTestLookupValue"></param>
    /// <param name="CaseOption"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAllowableValuesOnText(var TestNameForError: Text; var TextToValidate: Text[250]; var AllowableValues: Text; var QltyTestValueType: Enum "Qlty. Test Value Type"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary; var QltyCaseSensitivity: Enum "Qlty. Case Sensitivity")
    begin
    end;
}
