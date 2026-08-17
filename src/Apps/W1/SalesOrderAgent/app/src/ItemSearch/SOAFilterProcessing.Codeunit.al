// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Utilities;

/// <summary>
/// AL port of the platform NavFilterProcessingHelper filter semantics used to build
/// optimized "contains" filter expressions from free-text search input.
/// </summary>
codeunit 4601 "SOA Filter Processing"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Apostrophe: Label '''', Locked = true;
        TwoApostrophes: Label '''''', Locked = true;
        SingleEscapePatternTok: Label '(?<!'')''(?!'')', Locked = true;
        LetterOrDigitPatternTok: Label '[\p{L}\p{Nd}]', Locked = true;
        StartsWithWildcardTok: Label '@', Locked = true;
        ContainsWildcardTok: Label '*', Locked = true;
        ContainsWildcardIgnoreCaseTok: Label '@*', Locked = true;
        OptimizedContainsPrefixTok: Label '&&', Locked = true;
        ExpressionPrefixTok: Label '%', Locked = true;
        AndOperatorTok: Label '&', Locked = true;
        RangeSeparatorTok: Label '..', Locked = true;
        NeedsQuotingCharsTok: Label '|&<>=()', Locked = true;
        WildcardBlockingCharsTok: Label '|&<>%', Locked = true;
        EmptyFilterValueTok: Label '''''', Locked = true;

    /// <summary>
    /// Builds an optimized "contains" filter expression for the provided free-text value.
    /// The value is split into words (and quoted phrases), and each part is turned into a
    /// full-text search operator combined with AND.
    /// </summary>
    /// <param name="Value">The free-text search value.</param>
    /// <returns>The filter expression, or a plain contains filter when no word could be extracted.</returns>
    procedure AddOptimizedContainsOperator(Value: Text): Text
    var
        Builder: Text;
        Word: Text;
        Index, Length, WordStart, ClosingQuotePos : Integer;
        CurrentChar: Char;
    begin
        if Value.Trim() = '' then
            exit(Value);

        Index := 1;
        Length := StrLen(Value);
        while Index <= Length do begin
            CurrentChar := Value[Index];
            case true of
                CurrentChar = '"':
                    begin
                        ClosingQuotePos := FindClosingQuote(Value, Index + 1);
                        if ClosingQuotePos = 0 then
                            Index += 1 // Stray quote with no closing quote - skip it.
                        else begin
                            Word := CopyStr(Value, Index + 1, ClosingQuotePos - Index - 1);
                            AppendCreateFilterPart(Builder, Word.Trim(), true);
                            Index := ClosingQuotePos + 1;
                        end;
                    end;
                IsWhitespace(CurrentChar):
                    Index += 1;
                else begin
                    WordStart := Index;
                    while (Index <= Length) and (Value[Index] <> '"') and (not IsWhitespace(Value[Index])) do
                        Index += 1;
                    Word := CopyStr(Value, WordStart, Index - WordStart);
                    AppendCreateFilterPart(Builder, Word, false);
                end;
            end;
        end;

        if Builder <> '' then
            exit(Builder);

        exit(AddWildcardForContainsAndEndsWith(Value));
    end;

    local procedure AppendCreateFilterPart(var Builder: Text; Word: Text; Exact: Boolean)
    var
        FilterPart: Text;
    begin
        if (Word.Trim() = '') or (not HasLetterOrDigit(Word)) then
            exit;

        if Word.StartsWith(ContainsWildcardTok) or Word.StartsWith(ContainsWildcardIgnoreCaseTok) or Word.StartsWith(ExpressionPrefixTok) then begin
            // Begins with wildcard - full text search does not support suffix search, so fall back to regular LIKE search.
            FilterPart := DelChr(Word, '<', ContainsWildcardTok);
            if StrLen(FilterPart) <> StrLen(Word) then
                FilterPart := ContainsWildcardIgnoreCaseTok + FilterPart;
            FilterPart := EscapeFilterValueIfNeeded(FilterPart);
        end else begin
            // Remove existing wildcards and add the full text operator.
            FilterPart := DelChr(Word, '<>', ContainsWildcardTok);
            if not Exact then
                FilterPart += ContainsWildcardTok;
            FilterPart := OptimizedContainsPrefixTok + EscapeFilterValueIfNeeded(FilterPart);
        end;

        if StrLen(Builder) > 0 then
            Builder += AndOperatorTok;
        Builder += '(' + FilterPart + ')';
    end;

    local procedure AddWildcardForContainsAndEndsWith(Value: Text): Text
    begin
        if Value = '' then
            exit(Value);

        if CanAddWildcardToFilterValue(Value) then begin
            if not Value.StartsWith(ContainsWildcardIgnoreCaseTok) then
                Value := ContainsWildcardIgnoreCaseTok + Value;
            if not Value.EndsWith(ContainsWildcardTok) then
                Value += ContainsWildcardTok;
            Value := EscapeFilterValueIfNeeded(Value);
        end;

        exit(Value);
    end;

    local procedure EscapeFilterValueIfNeeded(FilterValue: Text): Text
    begin
        if (FilterValue <> EmptyFilterValueTok) and NeedsQuoting(FilterValue) then
            exit(EscapeFilterValue(FilterValue));
        exit(FilterValue);
    end;

    local procedure EscapeFilterValue(FilterValue: Text): Text
    var
        Regex: Codeunit Regex;
        SingleQuotesEscaped: Text;
    begin
        if FilterValue = '' then
            exit(FilterValue);

        SingleQuotesEscaped := Regex.Replace(FilterValue, SingleEscapePatternTok, TwoApostrophes);
        exit(Apostrophe + SingleQuotesEscaped + Apostrophe);
    end;

    local procedure NeedsQuoting(FilterValue: Text): Boolean
    begin
        // Matches the platform "needsQuoting" regex: ^\s*$ | [.]{2} | [|&<>=()']
        if FilterValue.Trim() = '' then
            exit(true);
        if FilterValue.Contains(RangeSeparatorTok) then
            exit(true);
        exit(ContainsAnyChar(FilterValue, NeedsQuotingCharsTok + Apostrophe));
    end;

    local procedure CanAddWildcardToFilterValue(Value: Text): Boolean
    begin
        if Value.Contains(RangeSeparatorTok) then // [.]{2}
            exit(false);
        if ContainsAnyChar(Value, WildcardBlockingCharsTok) then // [|&<>%]
            exit(false);
        if OccurrencesOfChars(Value, Apostrophe) >= 2 then // \s*'.*'\s*
            exit(false);
        if Value.Contains(StartsWithWildcardTok) then
            exit(false);
        if Value.Contains(ContainsWildcardTok) then
            exit(false);
        exit(true);
    end;

    local procedure HasLetterOrDigit(Word: Text): Boolean
    var
        Regex: Codeunit Regex;
    begin
        exit(Regex.IsMatch(Word, LetterOrDigitPatternTok));
    end;

    local procedure FindClosingQuote(Value: Text; StartIndex: Integer): Integer
    var
        Index: Integer;
    begin
        for Index := StartIndex to StrLen(Value) do
            if Value[Index] = '"' then
                exit(Index);
        exit(0);
    end;

    local procedure IsWhitespace(C: Char): Boolean
    begin
        exit(Format(C).Trim() = '');
    end;

    local procedure ContainsAnyChar(Value: Text; Chars: Text): Boolean
    begin
        exit(DelChr(Value, '=', Chars) <> Value);
    end;

    local procedure OccurrencesOfChars(Value: Text; Chars: Text): Integer
    begin
        exit(StrLen(Value) - StrLen(DelChr(Value, '=', Chars)));
    end;
}
