// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Parses a stability configuration string into the individual presets and applies them to the
/// stability context. A configuration is a '+' separated list of CODE tokens, for example
/// SEED-2+WORKDATEFUTURE-1YEAR+REVERSE-METHODS. Recognized tokens:
/// <list type="bullet">
/// <item>BASELINE - no preset (the empty string is equivalent).</item>
/// <item>SEED-&lt;n&gt; - force pseudo-random seed n in Any and Library - Random.</item>
/// <item>WORKDATEFUTURE-&lt;n&gt;YEAR / WORKDATEFUTURE-&lt;n&gt;MONTH - shift WorkDate into the future.</item>
/// <item>ONEBYONE - run each test method in isolation.</item>
/// <item>REVERSE-CODEUNITS - run the test codeunits in reverse order.</item>
/// <item>REVERSE-METHODS - run the test methods within a codeunit in reverse order.</item>
/// </list>
/// </summary>
codeunit 130469 "Stability Preset"
{
    Access = Internal;

    var
        SeedTok: Label 'SEED-', Locked = true;
        WorkDateFutureTok: Label 'WORKDATEFUTURE-', Locked = true;
        OneByOneTok: Label 'ONEBYONE', Locked = true;
        ReverseCodeunitsTok: Label 'REVERSE-CODEUNITS', Locked = true;
        ReverseMethodsTok: Label 'REVERSE-METHODS', Locked = true;
        BaselineTok: Label 'BASELINE', Locked = true;
        YearSuffixTok: Label 'YEAR', Locked = true;
        MonthSuffixTok: Label 'MONTH', Locked = true;
        UnknownTokenErr: Label 'Unknown stability configuration token ''%1'' in ''%2''.', Comment = '%1 = token, %2 = full configuration';

    /// <summary>
    /// Parses the configuration and applies the resulting presets to the stability context.
    /// </summary>
    /// <param name="StabilityContext">The context to populate.</param>
    /// <param name="Combination">The configuration string.</param>
    procedure ApplyToContext(var StabilityContext: Codeunit "Stability Context"; Combination: Text)
    var
        Tokens: List of [Text];
        Token: Text;
    begin
        Tokens := SplitCombination(Combination);
        foreach Token in Tokens do
            ApplyToken(StabilityContext, Token, Combination);
    end;

    /// <summary>
    /// Returns the WorkDate to use for the given offset formula relative to a base WorkDate.
    /// </summary>
    /// <param name="BaseWorkDate">The WorkDate captured at the start of the run.</param>
    /// <param name="OffsetFormula">A date formula, for example &lt;+1Y&gt;. Empty returns the base.</param>
    /// <returns>The shifted WorkDate.</returns>
    procedure GetShiftedWorkDate(BaseWorkDate: Date; OffsetFormula: Text[30]): Date
    var
        DateFormulaValue: DateFormula;
    begin
        if OffsetFormula = '' then
            exit(BaseWorkDate);
        Evaluate(DateFormulaValue, OffsetFormula);
        exit(CalcDate(DateFormulaValue, BaseWorkDate));
    end;

    local procedure SplitCombination(Combination: Text) Tokens: List of [Text]
    var
        RawToken: Text;
        NormalizedToken: Text;
    begin
        foreach RawToken in Combination.Split('+') do begin
            NormalizedToken := UpperCase(DelChr(RawToken, '<>', ' '));
            if NormalizedToken <> '' then
                Tokens.Add(NormalizedToken);
        end;
    end;

    local procedure ApplyToken(var StabilityContext: Codeunit "Stability Context"; Token: Text; Combination: Text)
    begin
        case true of
            Token = BaselineTok:
                exit;
            Token.StartsWith(SeedTok):
                StabilityContext.SetSeed(ParseInteger(CopyStr(Token, StrLen(SeedTok) + 1)));
            Token.StartsWith(WorkDateFutureTok):
                StabilityContext.SetWorkDateOffset(ParseWorkDateOffset(CopyStr(Token, StrLen(WorkDateFutureTok) + 1)));
            Token = OneByOneTok:
                StabilityContext.SetOneByOne(true);
            Token = ReverseCodeunitsTok:
                StabilityContext.SetReverseCodeunits(true);
            Token = ReverseMethodsTok:
                StabilityContext.SetReverseMethods(true);
            else
                Error(UnknownTokenErr, Token, Combination);
        end;
    end;

    local procedure ParseWorkDateOffset(Amount: Text) OffsetFormula: Text[30]
    var
        NumberPart: Text;
        UnitLetter: Text[1];
    begin
        if Amount.EndsWith(YearSuffixTok) then begin
            NumberPart := CopyStr(Amount, 1, StrLen(Amount) - StrLen(YearSuffixTok));
            UnitLetter := 'Y';
        end else
            if Amount.EndsWith(MonthSuffixTok) then begin
                NumberPart := CopyStr(Amount, 1, StrLen(Amount) - StrLen(MonthSuffixTok));
                UnitLetter := 'M';
            end else begin
                NumberPart := Amount;
                UnitLetter := 'Y';
            end;

        exit(CopyStr(StrSubstNo('<+%1%2>', ParseInteger(NumberPart), UnitLetter), 1, MaxStrLen(OffsetFormula)));
    end;

    local procedure ParseInteger(Value: Text): Integer
    var
        Result: Integer;
    begin
        if Evaluate(Result, Value) then
            exit(Result);
        exit(0);
    end;
}
