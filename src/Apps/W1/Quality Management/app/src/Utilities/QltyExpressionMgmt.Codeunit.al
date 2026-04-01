// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using System.Utilities;

/// <summary>
/// Used to help calculate expressions.
/// </summary>
codeunit 20416 "Qlty. Expression Mgmt."
{
    var
        TokenReplacementTok: Label '[%1]', Locked = true, Comment = '%1=the token name to replace';
        TableReplacementPatternRegExTok: Label '\[([^\[\]:]+):([^\[\]:]+)\]', Locked = true;
        Special3ParamFunctionPatternRegExTok: Label '\[(\w+)\(([^;\)\]]*);([^;\)\]]*);([^\)\]]*)\)\]', Locked = true;
        SpecialTableFormattedSuffixTok: Label 'F', Locked = true;
        SpecialTableFormatted0SuffixTok: Label '(F0)', Locked = true;
        SpecialTableFormatted1SuffixTok: Label '(F1)', Locked = true;
        SpecialTableFormatted2SuffixTok: Label '(F2)', Locked = true;
        SpecialTableFormatted9SuffixTok: Label '(F9)', Locked = true;
        SpecialTableItemTok: Label 'ITEM', Locked = true;
        SpecialTableItemAttributeTok: Label 'ATTRIBUTE', Locked = true;
        SpecialStringFunctionClassifyTok: Label 'CLASSIFY', Locked = true;
        SpecialStringFunctionReplaceTok: Label 'REPLACE', Locked = true;
        SpecialStringFunctionReplaceStrTok: Label 'REPLACESTR', Locked = true;
        SpecialStringFunctionCopystrTok: Label 'COPYSTR', Locked = true;
        SpecialStringFunctionSelectstrTok: Label 'SELECTSTR', Locked = true;
        SpecialStringFunctionLookupTok: Label 'LOOKUP', Locked = true;
        SpecialStringFunctionFormatNumTok: Label 'FORMATNUM', Locked = true;
        NotAnExpressionErr: Label 'The inspection line %1 for test %2 is not a text expression field.', Comment = '%1=the record id, %2=the test';
        RecreateInspectionErr: Label 'The inspection line %1 for test %2 does not match the template %3. This means the template could have changed since this inspection was made. Re-create this inspection to evaluate the expression.', Comment = '%1=the record id, %2=the test, %3=the template filters';
        BadReplacementExpressionTok: Label '?', Locked = true;
        UnableToGetTableValueTableNotFoundErr: Label 'Cannot find a table based on [%1]', Comment = '%1=the table name';
        UnableToGetFieldValueTableNotFoundErr: Label 'Cannot find a field [%1] in table [%2]', Comment = '%1=the field name, %2=the table name';
        SpecialTextFormulaOptionsTok: Label '[Item:No.],[ATTRIBUTE:AttributeName],[Measure:Min.Value],[CLASSIFY(IfThisText;MatchesThisText;ThenThisValue)],[REPLACE(SearchThisText;ReplaceThis;WithThis)],[COPYSTR(OriginalText;Position;Length)],[Lookup(TableName;FieldName;Field1=Value1)]', Locked = true;
        UOMTok: Label 'UOM', Locked = true;

    /// <summary>
    /// Evaluates a text expression on an inspection line for a specific inspection.
    /// Validates that the line is a text expression field type and matches its template configuration.
    /// 
    /// Behavior:
    /// - Validates value type is "Value Type Text Expression"
    /// - Retrieves expression formula from template line
    /// - Evaluates expression with inspection context
    /// - Updates inspection value if changed
    /// - Fires OnEvaluateTextExpressionOnInspectionLine for extensibility
    /// 
    /// Error conditions:
    /// - Not a text expression field → Error
    /// - Template mismatch → Error (suggests inspection needs recreation)
    /// 
    /// Common usage: Auto-calculating field values during inspection execution based on formulas.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line containing the expression to evaluate</param>
    /// <param name="CurrentQltyInspectionHeader">The inspection header providing context for evaluation</param>
    /// <returns>The evaluated text result</returns>
    internal procedure EvaluateTextExpression(var QltyInspectionLine: Record "Qlty. Inspection Line"; CurrentQltyInspectionHeader: Record "Qlty. Inspection Header") Result: Text
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        Value: Text;
    begin
        QltyInspectionLine.CalcFields("Test Value Type");
        if QltyInspectionLine."Test Value Type" <> QltyInspectionLine."Test Value Type"::"Value Type Text Expression" then
            Error(NotAnExpressionErr, QltyInspectionLine.RecordId(), QltyInspectionLine."Test Code");

        QltyInspectionTemplateLine.Get(QltyInspectionLine."Template Code", QltyInspectionLine."Template Line No.");
        QltyInspectionTemplateLine.SetRecFilter();
        QltyInspectionTemplateLine.SetRange("Test Code", QltyInspectionLine."Test Code");
        if not QltyInspectionTemplateLine.FindFirst() then
            Error(RecreateInspectionErr, QltyInspectionLine.RecordId(), QltyInspectionLine."Test Code", QltyInspectionTemplateLine.GetFilters());

        if QltyInspectionTemplateLine."Expression Formula" = '' then
            exit('');

        Value := EvaluateTextExpression(QltyInspectionTemplateLine."Expression Formula", CurrentQltyInspectionHeader, QltyInspectionLine);
        OnEvaluateTextExpressionOnInspectionLine(QltyInspectionLine, CurrentQltyInspectionHeader, QltyInspectionTemplateLine, QltyInspectionTemplateLine."Expression Formula", Value);

        if (Value <> QltyInspectionLine."Test Value") or (QltyInspectionLine."Test Value" = '') then begin
            QltyInspectionLine.Validate("Test Value", Value);
            QltyInspectionLine.Modify();
        end;
        Result := Value;
    end;

    /// <summary>
    /// Evaluates a text expression, using fields on the quality inspection as text replacement options.
    /// Does *not* evaluate embedded expressions.
    /// Provides simplified overload with only inspection header context.
    /// 
    /// Token replacement: Replaces [FieldName] tokens with actual field values from inspection header.
    /// Use case: Simple field substitution in templates, labels, or filter expressions.
    /// </summary>
    /// <param name="Input">The text expression containing [FieldName] tokens to replace</param>
    /// <param name="CurrentQltyInspectionHeader">If the inspection doesn't exist pass in a blank empty temporary record instead.</param>
    /// <returns>The evaluated text with tokens replaced by actual values</returns>
    internal procedure EvaluateTextExpression(Input: Text; CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"): Text
    var
        TempDummyQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        exit(EvaluateTextExpression(Input, CurrentQltyInspectionHeader, TempDummyQltyInspectionLine));
    end;

    /// <summary>
    /// Evaluates a text expression, using fields on the quality inspection as text replacement options.
    /// Does *not* evaluate embedded expressions.
    /// Supports both inspection header and inspection line field references.
    /// 
    /// Token replacement: Replaces [FieldName] tokens with actual field values from inspection header and line.
    /// Use case: Field substitution with line-level context (e.g., measure-specific calculations).
    /// </summary>
    /// <param name="Input">The text expression containing [FieldName] tokens to replace</param>
    /// <param name="CurrentQltyInspectionHeader">If the inspection doesn't exist pass in a blank empty temporary record instead.</param>
    /// <param name="CurrentQltyInspectionLine">If the inspection line doesn't exist pass in a blank empty temporary record instead.</param>
    /// <returns>The evaluated text with tokens replaced by actual values</returns>
    internal procedure EvaluateTextExpression(Input: Text; CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; CurrentQltyInspectionLine: Record "Qlty. Inspection Line"): Text
    begin
        exit(EvaluateTextExpression(Input, CurrentQltyInspectionHeader, CurrentQltyInspectionLine, false));
    end;

    /// <summary>
    /// Evaluates a text expression, using fields on the quality inspection as text replacement options.
    /// Set EvaluateEmbeddedNumericExpressions to true to evaluate embedded expressions.
    /// Internal overload for controlling embedded expression evaluation without line context.
    /// </summary>
    /// <param name="Input">The text expression to evaluate</param>
    /// <param name="CurrentQltyInspectionHeader">The inspection header providing field values for token replacement</param>
    /// <param name="EvaluateEmbeddedNumericExpressions">True to evaluate {expression} patterns; False to skip</param>
    /// <returns>The evaluated text with tokens replaced and optional embedded expressions evaluated</returns>
    internal procedure EvaluateTextExpression(Input: Text; CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; EvaluateEmbeddedNumericExpressions: Boolean): Text
    var
        TempDummySpecificQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        exit(EvaluateTextExpression(Input, CurrentQltyInspectionHeader, TempDummySpecificQltyInspectionLine, EvaluateEmbeddedNumericExpressions));
    end;

    /// <summary>
    /// Evaluates a text expression, using fields on the quality inspection as text replacement options.
    /// Set EvaluateEmbeddedNumericExpressions to true to evaluate embedded expressions.
    /// Core evaluation method supporting full context and embedded expression evaluation.
    /// 
    /// Features:
    /// - Token replacement: [FieldName] → field value
    /// - Embedded expressions: {numerical expression} → calculated value (if enabled)
    /// - Table lookups: [TableName:FieldName] → field value from related records
    /// - String functions: CLASSIFY(), REPLACE(), COPYSTR(), SELECTSTR(), LOOKUP(), FORMATNUM()
    /// 
    /// Common usage: Complex expression evaluation in templates with full inspection context.
    /// </summary>
    /// <param name="Input">The text expression to evaluate</param>
    /// <param name="CurrentQltyInspectionHeader">The inspection header providing field values for token replacement</param>
    /// <param name="SpecificQltyInspectionLine">When supplied, a specific inspection line providing additional context</param>
    /// <param name="EvaluateEmbeddedNumericExpressions">True to evaluate {expression} patterns; False to skip</param>
    /// <returns>The fully evaluated text result</returns>
    internal procedure EvaluateTextExpression(Input: Text; CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; SpecificQltyInspectionLine: Record "Qlty. Inspection Line"; EvaluateEmbeddedNumericExpressions: Boolean) Result: Text
    var
        InputCurrentQltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        CustQltyTest: Record "Qlty. Test";
        SearchFor: Text;
    begin
        Input := TextReplace(Input, StrSubstNo(TokenReplacementTok, UOMTok), SpecificQltyInspectionLine."Unit of Measure Code");
        Input := EvaluateBuiltInTableLookups(Input, CurrentQltyInspectionHeader, SpecificQltyInspectionLine);
        InputCurrentQltyInspectionLine.SetRange("Line No.");
        InputCurrentQltyInspectionLine.SetRange("Inspection No.", CurrentQltyInspectionHeader."No.");
        InputCurrentQltyInspectionLine.SetRange("Re-inspection No.", CurrentQltyInspectionHeader."Re-inspection No.");

        Result := EvaluateExpressionForRecord(Input, CurrentQltyInspectionHeader, false);

        if (InputCurrentQltyInspectionLine.FindSet() and (CurrentQltyInspectionHeader."No." <> '') and (not CurrentQltyInspectionHeader.IsTemporary())) then
            repeat
                SearchFor := StrSubstno(TokenReplacementTok, InputCurrentQltyInspectionLine."Test Code");
                if InputCurrentQltyInspectionLine.IsNumericFieldType() then
                    Result := TextReplace(Result, SearchFor, Format(InputCurrentQltyInspectionLine."Derived Numeric Value", 0, 1), "Qlty. Case Sensitivity"::Insensitive)
                else
                    Result := TextReplace(Result, SearchFor, InputCurrentQltyInspectionLine."Test Value", "Qlty. Case Sensitivity"::Insensitive);
            until InputCurrentQltyInspectionLine.Next() = 0
        else begin
            QltyInspectionTemplateLine.Reset();
            QltyInspectionTemplateLine.SetRange("Template Code", InputCurrentQltyInspectionLine.GetFilter("Template Code"));
            QltyInspectionTemplateLine.SetLoadFields("Test Code");
            if QltyInspectionTemplateLine.FindSet() then
                repeat
                    SearchFor := StrSubstno(TokenReplacementTok, QltyInspectionTemplateLine."Test Code");
                    Result := TextReplace(Result, SearchFor, '');
                until QltyInspectionTemplateLine.Next() = 0
            else begin
                CustQltyTest.Reset();
                CustQltyTest.SetLoadFields("Code");
                if CustQltyTest.FindSet() then
                    repeat
                        SearchFor := StrSubstno(TokenReplacementTok, CustQltyTest.Code);
                        Result := TextReplace(Result, SearchFor, '');
                    until CustQltyTest.Next() = 0;
            end;
        end;
        Result := EvaluateStringOnlyFunctions(Result);
    end;

    /// <summary>
    /// This will replace [fieldname] tokens with the field value for the supplied data.
    /// </summary>
    /// <param name="Input"></param>
    /// <param name="RecordVariant"></param>
    /// <param name="FormatText">Set to true to use localization format, set to false to not format.</param>
    /// <returns></returns>
    internal procedure EvaluateExpressionForRecord(Input: Text; RecordVariant: Variant; FormatText: Boolean) Result: Text
    var
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        AlternateRecordRef: RecordRef;
        SearchForFieldRef: FieldRef;
        MaxFields: Integer;
        FieldIterator: Integer;
        SearchFor: Text;
        ReplaceWith: Text;
    begin
        Result := Input;

        if not QltyMiscHelpers.GetRecordRefFromVariant(RecordVariant, AlternateRecordRef) then
            exit(Result);

        MaxFields := AlternateRecordRef.FieldCount();
        for FieldIterator := 1 to MaxFields do begin
            SearchForFieldRef := AlternateRecordRef.FieldIndex(FieldIterator);
            if SearchForFieldRef.Class() = FieldClass::FlowField then
                SearchForFieldRef.CalcField();

            SearchFor := StrSubstno(TokenReplacementTok, SearchForFieldRef.Name());

            if FormatText then
                ReplaceWith := Format(SearchForFieldRef.Value())
            else
                ReplaceWith := Format(SearchForFieldRef.Value(), 0, 9);

            if ReplaceWith = '0' then
                if (AlternateRecordRef.Number() = Database::"Qlty. Inspection Header") and (SearchForFieldRef.Number() = TempQltyInspectionHeader.FieldNo("Re-inspection No.")) then
                    ReplaceWith := '';

            Result := TextReplace(Result, SearchFor, ReplaceWith, "Qlty. Case Sensitivity"::Insensitive);
        end;
    end;

    /// <summary>
    /// Replaces all occurrences of a search string with a replacement string (case-sensitive by default).
    /// Simplified overload using case-sensitive comparison.
    /// </summary>
    /// <param name="Input">The text to search within</param>
    /// <param name="SearchFor">The text to search for</param>
    /// <param name="ReplaceWith">The text to replace matches with</param>
    /// <returns>The text with all occurrences replaced</returns>
    internal procedure TextReplace(Input: Text; SearchFor: Text; ReplaceWith: Text): Text
    begin
        exit(TextReplace(Input, SearchFor, ReplaceWith, "Qlty. Case Sensitivity"::Sensitive));
    end;

    /// <summary>
    /// Replaces all occurrences of a search string with a replacement string.
    /// Supports case-sensitive or case-insensitive matching.
    /// 
    /// Algorithm: Iterative search-and-replace maintaining original casing in output for matched portions.
    /// 
    /// Use cases:
    /// - Case-sensitive: Exact token replacement in expressions
    /// - Case-insensitive: User-friendly field name matching
    /// </summary>
    /// <param name="Input">The text to search within</param>
    /// <param name="SearchFor">The text to search for</param>
    /// <param name="ReplaceWith">The text to replace matches with</param>
    /// <param name="QltyCaseSensitivity">Sensitive for exact matching; Insensitive for case-insensitive matching</param>
    /// <returns>The text with all occurrences replaced</returns>
    internal procedure TextReplace(Input: Text; SearchFor: Text; ReplaceWith: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity") ResultText: Text
    var
        InputLen: Integer;
        SearchLen: Integer;
        FindFirst: Integer;
        LowerInput: Text;
        LowerSearchFor: Text;
    begin
        InputLen := StrLen(Input);
        SearchLen := StrLen(SearchFor);
        if QltyCaseSensitivity = QltyCaseSensitivity::Insensitive then begin
            LowerInput := LowerCase(Input);
            LowerSearchFor := LowerCase(SearchFor);
        end else begin
            LowerInput := Input;
            LowerSearchFor := SearchFor;
        end;

        if (InputLen > 0) and (SearchLen > 0) then begin
            FindFirst := StrPos(LowerInput, LowerSearchFor);
            while (FindFirst > 0) do begin
                ResultText := ResultText + CopyStr(Input, 1, FindFirst - 1);
                ResultText := ResultText + ReplaceWith;
                Input := DelStr(Input, 1, FindFirst + SearchLen - 1);
                LowerInput := DelStr(LowerInput, 1, FindFirst + SearchLen - 1);
                FindFirst := StrPos(LowerInput, LowerSearchFor);
            end;

            ResultText := ResultText + Input;
        end else
            ResultText := Input;
    end;

    internal procedure ConvertCarriageReturnsToHTMLBRs(Input: Text) ResultText: Text
    var
        LineFeed: Char;
        CarriageReturn: Char;
    begin
        ResultText := Input;
        if ResultText <> '' then begin
            CarriageReturn := 13;
            LineFeed := 10;
            ResultText := TextReplace(ResultText, Format(CarriageReturn) + Format(LineFeed), '<br />');
            ResultText := TextReplace(ResultText, Format(CarriageReturn), '<br />');
            ResultText := TextReplace(ResultText, Format(LineFeed), '<br />');
        end;
    end;

    internal procedure ConvertHTMLBRsToCarriageReturns(Input: Text) ResultText: Text
    var
        LineFeed: Char;
        CarriageReturn: Char;
    begin
        ResultText := Input;
        if ResultText <> '' then begin
            CarriageReturn := 13;
            LineFeed := 10;
            ResultText := TextReplace(ResultText, '<br />', Format(CarriageReturn) + Format(LineFeed));
            ResultText := TextReplace(ResultText, '<br/>', Format(CarriageReturn) + Format(LineFeed));
            ResultText := TextReplace(ResultText, '<br>', Format(CarriageReturn) + Format(LineFeed));
        end;
    end;

    /// <summary>
    /// **** Only used for validation**** Do not use for completely evaluating a string expression.
    /// Tests whether special string functions can be parsed without executing full evaluation.
    /// Used for validation during template design to catch syntax errors early.
    /// 
    /// Validated functions: CLASSIFY(), REPLACE(), COPYSTR(), SELECTSTR(), LOOKUP(), FORMATNUM()
    /// 
    /// Note: Does not evaluate with real data - only tests syntax and structure.
    /// </summary>
    /// <param name="Input">The text expression containing special functions to validate</param>
    /// <returns>The text with validated function syntax (not fully evaluated)</returns>
    internal procedure TestEvaluateSpecialStringFunctions(Input: Text): Text
    var
        TempCurrentQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        TempDummyCurrentQltyInspectionLine: Record "Qlty. Inspection Line" temporary;
    begin
        exit(TestEvaluateSpecialStringFunctions(Input, TempCurrentQltyInspectionHeader, TempDummyCurrentQltyInspectionLine))
    end;

    /// <summary>
    /// Only used for testing expressions.
    /// </summary>
    /// <param name="Input"></param>
    /// <param name="CurrentQltyInspectionHeader"></param>
    /// <returns></returns>
    local procedure TestEvaluateSpecialStringFunctions(Input: Text; var CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; var CurrentQltyInspectionLine: Record "Qlty. Inspection Line") Result: Text
    begin
        Result := Input;
        Result := EvaluateBuiltInTableLookups(Result, CurrentQltyInspectionHeader, CurrentQltyInspectionLine);
        Result := EvaluateStringOnlyFunctions(Result);
    end;

    local procedure EvaluateStringOnlyFunctions(Input: Text) Result: Text
    var
        Continue: Boolean;
        Previous: Text;
        SafetyLimit: Integer;
    begin
        Result := Input;
        Previous := Result;
        SafetyLimit := DefaultMaxRowsFieldLookup();
        repeat
            SafetyLimit -= 1;
            Result := EvaluateFirstStringOnlyFunctions(Result);
            Continue := (SafetyLimit > 0) and (Result <> Previous);
            Previous := Result;
        until not Continue;
    end;

    local procedure DefaultMaxRowsFieldLookup(): Integer
    begin
        exit(100);
    end;

    local procedure EvaluateFirstStringOnlyFunctions(Input: Text) Result: Text
    var
        TempRegexMatches: Record Matches temporary;
        TempRegexGroups: Record Groups temporary;
        Regex: Codeunit Regex;
        StringFunctionName: Text;
        RawParameter1: Text;
        RawParameter2: Text;
        RawParameter3: Text;
        ValueToReplaceWith: Text;
        EntireFindText: Text;
        ConvertedAsIntParameter1: Integer;
        ConvertedAsIntParameter2: Integer;
        ConvertedAsIntParameter3: Integer;
        ConvertedAsDecParameter1: Decimal;
        IsHandled: Boolean;
    begin
        Result := Input;
        Clear(TempRegexMatches);
        Regex.Match(Result, Special3ParamFunctionPatternRegExTok, TempRegexMatches);
        if TempRegexMatches.FindFirst() then
            repeat
                Clear(TempRegexGroups);
                Clear(EntireFindText);
                ValueToReplaceWith := BadReplacementExpressionTok;
                Regex.Groups(TempRegexMatches, TempRegexGroups);
                if TempRegexGroups.Count() = 5 then begin
                    EntireFindText := TempRegexGroups.ReadValue();
                    TempRegexGroups.Next();
                    StringFunctionName := TempRegexGroups.ReadValue();
                    TempRegexGroups.Next();
                    RawParameter1 := TempRegexGroups.ReadValue();
                    TempRegexGroups.Next();
                    RawParameter2 := TempRegexGroups.ReadValue();
                    TempRegexGroups.Next();
                    RawParameter3 := TempRegexGroups.ReadValue();
                    IsHandled := false;
                    OnBeforeEvaluateStringOnlyFunctionThreeParamExpression(Result, StringFunctionName, RawParameter1, RawParameter2, RawParameter3, EntireFindText, ValueToReplaceWith, IsHandled);
                    if not IsHandled then begin
                        case StringFunctionName.ToUpper() of
                            SpecialStringFunctionReplaceTok, SpecialStringFunctionReplaceStrTok:
                                ValueToReplaceWith := RawParameter1.Replace(RawParameter2, RawParameter3);
                            SpecialStringFunctionCopystrTok:
                                begin
                                    Evaluate(ConvertedAsIntParameter2, RawParameter2);
                                    Evaluate(ConvertedAsIntParameter3, RawParameter3);
                                    ValueToReplaceWith := CopyStr(RawParameter1, ConvertedAsIntParameter2, ConvertedAsIntParameter3);
                                end;
                            SpecialStringFunctionSelectstrTok:
                                begin
                                    Evaluate(ConvertedAsIntParameter1, RawParameter1);
                                    ValueToReplaceWith := SelectStr(ConvertedAsIntParameter1, RawParameter2);
                                end;
                            SpecialStringFunctionClassifyTok:
                                if RawParameter1 = RawParameter2 then
                                    ValueToReplaceWith := RawParameter3
                                else
                                    ValueToReplaceWith := '';
                            SpecialStringFunctionLookupTok:
                                ValueToReplaceWith := LookupFieldValueBasedOn(RawParameter1, RawParameter2, RawParameter3);
                            SpecialStringFunctionFormatNumTok:
                                begin
                                    Evaluate(ConvertedAsDecParameter1, RawParameter1);
                                    Evaluate(ConvertedAsIntParameter2, RawParameter2);
                                    ValueToReplaceWith := Format(ConvertedAsDecParameter1, 0, ConvertedAsIntParameter2);
                                end;
                            else
                                OnEvaluateCustomStringOnlyFunctionThreeParamExpression(Result, StringFunctionName, RawParameter1, RawParameter2, RawParameter3, EntireFindText, ValueToReplaceWith);
                        end;
                        Result := TextReplace(Result, EntireFindText, ValueToReplaceWith);
                    end;
                end;

            until TempRegexMatches.Next() = 0;
    end;

    local procedure LookupFieldValueBasedOn(TableName: Text; NumberOrNameOfFieldToLookup: Text; ConditionalFilter: Text) Result: Text
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        RecordRefToRead: RecordRef;
        FieldRefToLookup: FieldRef;
        TableToOpen: Integer;
        FieldNumber: Integer;
    begin
        TableToOpen := QltyFilterHelpers.IdentifyTableIDFromText(TableName);
        if TableToOpen = 0 then
            Error(UnableToGetTableValueTableNotFoundErr, TableName);

        RecordRefToRead.Open(TableToOpen);

        QltyFilterHelpers.SetFiltersByExpressionSyntax(RecordRefToRead, ConditionalFilter);

        FieldNumber := QltyFilterHelpers.IdentifyFieldIDFromText(TableToOpen, NumberOrNameOfFieldToLookup);

        if FieldNumber = 0 then
            Error(UnableToGetFieldValueTableNotFoundErr, NumberOrNameOfFieldToLookup, TableName);
        FieldRefToLookup := RecordRefToRead.Field(FieldNumber);

        if RecordRefToRead.FindFirst() then
            Result := QltyMiscHelpers.ReadFieldAsText(RecordRefToRead, NumberOrNameOfFieldToLookup, 1);
    end;

    local procedure EvaluateBuiltInTableLookups(Input: Text; var CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; var CurrentQltyInspectionLine: Record "Qlty. Inspection Line") Result: Text
    var
        Item: Record Item;
        TempRegexMatches: Record Matches temporary;
        TempRegexGroups: Record Groups temporary;
        Regex: Codeunit Regex;
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        TableName: Text;
        FieldName: Text;
        ValueToReplaceWith: Text;
        EntireFindText: Text;
        IsHandled: Boolean;
        FormatKind: Integer;
    begin
        OnBeforeEvaluateBuiltInTableLookups(Input, CurrentQltyInspectionHeader, CurrentQltyInspectionLine, Result, IsHandled);
        if IsHandled then
            exit;

        Result := Input;
        Clear(TempRegexMatches);
        Regex.Match(Result, TableReplacementPatternRegExTok, TempRegexMatches);
        if TempRegexMatches.FindSet() then
            repeat
                Clear(TempRegexGroups);
                Clear(EntireFindText);
                ValueToReplaceWith := BadReplacementExpressionTok;
                Regex.Groups(TempRegexMatches, TempRegexGroups);
                if TempRegexGroups.Count() = 3 then begin
                    EntireFindText := TempRegexGroups.ReadValue();
                    TempRegexGroups.Next();
                    TableName := TempRegexGroups.ReadValue();
                    TempRegexGroups.Next();
                    FieldName := TempRegexGroups.ReadValue();
                    IsHandled := false;
                    OnBeforeEvaluateTableFieldInExpression(Result, TableName, FieldName, EntireFindText, ValueToReplaceWith, IsHandled);
                    if not IsHandled then begin
                        FormatKind := 1;
                        case true of
                            TableName.EndsWith(SpecialTableFormattedSuffixTok) and (StrLen(TableName) > 1):
                                begin
                                    TableName := TableName.Substring(1, StrLen(TableName) - 1);
                                    FormatKind := 0;
                                end;
                            TableName.EndsWith(SpecialTableFormatted0SuffixTok) and (StrLen(TableName) > StrLen(SpecialTableFormatted0SuffixTok)):
                                begin
                                    TableName := TableName.Substring(1, StrLen(TableName) - StrLen(SpecialTableFormatted0SuffixTok));
                                    FormatKind := 0;
                                end;
                            TableName.EndsWith(SpecialTableFormatted1SuffixTok) and (StrLen(TableName) > StrLen(SpecialTableFormatted1SuffixTok)):
                                begin
                                    TableName := TableName.Substring(1, StrLen(TableName) - StrLen(SpecialTableFormatted1SuffixTok));
                                    FormatKind := 1;
                                end;
                            TableName.EndsWith(SpecialTableFormatted2SuffixTok) and (StrLen(TableName) > StrLen(SpecialTableFormatted2SuffixTok)):
                                begin
                                    TableName := TableName.Substring(1, StrLen(TableName) - StrLen(SpecialTableFormatted2SuffixTok));
                                    FormatKind := 2;
                                end;
                            TableName.EndsWith(SpecialTableFormatted9SuffixTok) and (StrLen(TableName) > StrLen(SpecialTableFormatted9SuffixTok)):
                                begin
                                    TableName := TableName.Substring(1, StrLen(TableName) - StrLen(SpecialTableFormatted9SuffixTok));
                                    FormatKind := 9;
                                end;
                        end;

                        case TableName.ToUpper() of
                            SpecialTableItemTok:
                                begin
                                    if Item."No." = '' then
                                        CurrentQltyInspectionHeader.GetRelatedItem(Item);
                                    ValueToReplaceWith := QltyMiscHelpers.ReadFieldAsText(Item, FieldName, FormatKind)
                                end;
                            SpecialTableItemAttributeTok:
                                ValueToReplaceWith := CurrentQltyInspectionHeader.GetItemAttributeValue(FieldName);
                            else
                                OnEvaluateCustomTableFieldInExpression(Input, CurrentQltyInspectionHeader, CurrentQltyInspectionLine, Result, TableName, FieldName, EntireFindText, ValueToReplaceWith);
                        end;
                        Result := TextReplace(Result, EntireFindText, ValueToReplaceWith);
                    end;
                end;

            until TempRegexMatches.Next() = 0;
    end;

    /// <summary>
    /// Gets available text formula options as a CSV string for reference/documentation.
    /// Returns supported token patterns and function syntaxes for text expressions.
    /// 
    /// Returned patterns include:
    /// - Field tokens: [Item:No.], [ATTRIBUTE:AttributeName], [Measure:Min.Value]
    /// - Functions: CLASSIFY(), REPLACE(), COPYSTR(), Lookup()
    /// 
    /// Common usage: Displaying help text in UI, documenting expression capabilities, validation reference.
    /// </summary>
    /// <returns>Comma-separated list of available text formula patterns and functions</returns>
    internal procedure GetTextFormulaOptions(): Text
    begin
        exit(SpecialTextFormulaOptionsTok);
    end;

    /// <summary>
    /// Occurs before a text expression is evaluated on an inspection line.
    /// </summary>
    /// <param name="QltyInspectionLine"></param>
    /// <param name="CurrentQltyInspectionHeader"></param>
    /// <param name="QltyInspectionTemplateLine"></param>
    /// <param name="ExpressionInput"></param>
    /// <param name="ExpressionResultOutput"></param>
    [IntegrationEvent(false, false)]
    local procedure OnEvaluateTextExpressionOnInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line"; CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; ExpressionInput: Text; var ExpressionResultOutput: Text)
    begin
    end;

    /// <summary>
    /// Allows system replacement before evaluation of built-in table lookups.
    /// </summary>
    /// <param name="Input"></param>
    /// <param name="CurrentQltyInspectionHeader"></param>
    /// <param name="CurrentQltyInspectionLine"></param>
    /// <param name="Result"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateBuiltInTableLookups(var Input: Text; var CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; var CurrentQltyInspectionLine: Record "Qlty. Inspection Line"; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event for evaluating custom table field references in expressions.
    /// </summary>
    /// <param name="Input"></param>
    /// <param name="CurrentQltyInspectionHeader"></param>
    /// <param name="CurrentQltyInspectionLine"></param>
    /// <param name="EntireTextBeingEvaluated"></param>
    /// <param name="TableName"></param>
    /// <param name="NumberOrNameOfFieldName"></param>
    /// <param name="EntireFindText"></param>
    /// <param name="EntireReplaceText"></param>
    [IntegrationEvent(false, false)]
    procedure OnEvaluateCustomTableFieldInExpression(var Input: Text; var CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; var CurrentQltyInspectionLine: Record "Qlty. Inspection Line"; var EntireTextBeingEvaluated: Text; var TableName: Text; var NumberOrNameOfFieldName: Text; var EntireFindText: Text; var EntireReplaceText: Text)
    begin
    end;

    /// <summary>
    /// Use this to supplement or replace the [specialtable:fieldname] nomenclature
    /// when using text expressions.
    /// Set Handled to true to completely replace the default behavior in the loop.
    /// Set Handled to false to just extend it.
    /// </summary>
    /// <param name="EntireTextBeingEvaluated">For example [specialtable:fieldname] </param>
    /// <param name="TableName">specialtable in [specialtable:fieldname]</param>
    /// <param name="NumberOrNameOfFieldName">fieldname in [specialtable:fieldname]</param>
    /// <param name="EntireFindText">[specialtable:fieldname] in [specialtable:fieldname]</param>
    /// <param name="EntireReplaceText">your replacement</param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateTableFieldInExpression(var EntireTextBeingEvaluated: Text; var TableName: Text; var NumberOrNameOfFieldName: Text; var EntireFindText: Text; var EntireReplaceText: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to supplement or replace the [stringfunction(param1;param2;param3)] nomenclature
    /// when using text expressions.
    /// Set Handled to true to completely replace the default behavior in the loop.
    /// Set Handled to false to just extend it.
    /// </summary>
    /// <param name="EntireTextBeingEvaluated"></param>
    /// <param name="StringFunction"></param>
    /// <param name="Param1"></param>
    /// <param name="Param2"></param>
    /// <param name="Param3"></param>
    /// <param name="EntireFindText"></param>
    /// <param name="EntireReplaceText"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateStringOnlyFunctionThreeParamExpression(var EntireTextBeingEvaluated: Text; var StringFunction: Text; var Param1: Text; var Param2: Text; var Param3: Text; var EntireFindText: Text; var EntireReplaceText: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Use this to add your own string only functions [stringfunction(param1;param2;param3)] nomenclature
    /// when using text expressions.
    /// </summary>
    /// <param name="EntireTextBeingEvaluated"></param>
    /// <param name="StringFunction"></param>
    /// <param name="Param1"></param>
    /// <param name="Param2"></param>
    /// <param name="Param3"></param>
    /// <param name="EntireFindText"></param>
    /// <param name="EntireReplaceText"></param>
    [IntegrationEvent(false, false)]
    local procedure OnEvaluateCustomStringOnlyFunctionThreeParamExpression(var EntireTextBeingEvaluated: Text; var StringFunction: Text; var Param1: Text; var Param2: Text; var Param3: Text; var EntireFindText: Text; var EntireReplaceText: Text)
    begin
    end;
}
