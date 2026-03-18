// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

codeunit 921 "Period Formula Parser"
{
    var
        CurrentPeriodTok: Label 'CP';
        FiscalYearTok: Label 'FY';
        LastPeriodTok: Label 'LP';
        PeriodFormulaErr: Label '%1 is not a valid Period Formula.', Comment = '%1 - value of Comparison Period Formula field';
        PeriodTok: Label 'P', MaxLength = 10;

    procedure ValidatePeriodFormula(PeriodFormula: Code[20]; var LanguageId: Integer)
    var
        RangeFromInt: Integer;
        RangeToInt: Integer;
        Steps: Integer;
        Type: Enum "Period Type";
        RangeFromType: Enum "Period Formula Range";
        RangeToType: Enum "Period Formula Range";
    begin
        LanguageId := GlobalLanguage();
        ParsePeriodFormula(
          PeriodFormula, Steps, Type,
          RangeFromType, RangeToType, RangeFromInt, RangeToInt,
          LanguageId);
    end;

    [TryFunction]
    procedure TryCalculatePeriodStartEnd(PeriodFormula: Code[20]; LanguageId: Integer; Date: Date; var StartDate: Date; var EndDate: Date; var PeriodError: Boolean)
    begin
        CalculatePeriodStartEnd(PeriodFormula, LanguageId, Date, StartDate, EndDate, PeriodError);
    end;

    procedure CalculatePeriodStartEnd(PeriodFormula: Code[20]; LanguageId: Integer; Date: Date; var StartDate: Date; var EndDate: Date; var PeriodError: Boolean)
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        RangeFromInt: Integer;
        RangeToInt: Integer;
        Steps: Integer;
        Type: Enum "Period Type";
        RangeFromType: Enum "Period Formula Range";
        RangeToType: Enum "Period Formula Range";
    begin
        if PeriodFormula = '' then
            exit;

        ParsePeriodFormula(
          PeriodFormula, Steps, Type,
          RangeFromType, RangeToType, RangeFromInt, RangeToInt,
          LanguageId);

        AccountingPeriodMgt.AccPeriodStartEnd(
          Date, StartDate, EndDate, PeriodError, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);
    end;

    procedure ParsePeriodFormula(FormulaExpression: Code[20]; var LanguageId: Integer)
    var
        Steps: Integer;
        RangeFromInt: Integer;
        RangeToInt: Integer;
        Type: Enum "Period Type";
        RangeFromType: Enum "Period Formula Range";
        RangeToType: Enum "Period Formula Range";
    begin
        ParsePeriodFormula(FormulaExpression, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt, LanguageId);
    end;

    procedure ParsePeriodFormula(FormulaExpression: Code[20]; var Steps: Integer; var Type: Enum "Period Type"; var RangeFromType: Enum "Period Formula Range"; var RangeToType: Enum "Period Formula Range"; var RangeFromInt: Integer; var RangeToInt: Integer; var LanguageId: Integer)
    var
        FormulaParsed: Boolean;
        OldLanguageID: Integer;
    begin
        if LanguageId = 0 then
            LanguageId := GlobalLanguage();

        OldLanguageID := GlobalLanguage;
        GlobalLanguage(LanguageId);
        FormulaParsed := TryParsePeriodFormula(FormulaExpression, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);
        GlobalLanguage(OldLanguageID);

        if not FormulaParsed then
            Error(GetLastErrorText);
    end;

    [TryFunction]
    local procedure TryParsePeriodFormula(FormulaExpression: Code[20]; var Steps: Integer; var Type: Enum "Period Type"; var RangeFromType: Enum "Period Formula Range"; var RangeToType: Enum "Period Formula Range"; var RangeFromInt: Integer; var RangeToInt: Integer)
    var
        OriginalFormula: Code[20];
    begin
        // <PeriodFormula> ::= <signed integer> <formula> | blank
        // <signed integer> ::= <sign> <positive integer> | blank
        // <sign> ::= + | - | blank
        // <positive integer> ::= <digit 1-9> <digits>
        // <digit 1-9> ::= 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
        // <digits> ::= 0 <digits> | <digit 1-9> <digits> | blank
        // <formula> ::= P | FY <range> | FH <range> | FQ <range>
        // <range> ::= blank | [<range2>]
        // <range2> ::= <index> .. <index> | <index>
        // <index> ::= <positive integer> | CP | LP

        OriginalFormula := FormulaExpression;
        FormulaExpression := DelChr(FormulaExpression);

        if not ParseFormula(FormulaExpression, Steps, Type) then
            Error(PeriodFormulaErr, OriginalFormula);

        if Type = Type::"Fiscal Year" then
            if not ParseRange(FormulaExpression, RangeFromType, RangeFromInt, RangeToType, RangeToInt) then
                Error(PeriodFormulaErr, OriginalFormula);

        if FormulaExpression <> '' then
            Error(PeriodFormulaErr, OriginalFormula);
    end;

    local procedure ParseFormula(var FormulaExpression: Code[20]; var Steps: Integer; var Type: Enum "Period Type"): Boolean
    begin
        Steps := 0;
        Type := Type::" ";

        if FormulaExpression = '' then
            exit(true);

        if not ParseSignedInteger(FormulaExpression, Steps) then
            exit(false);

        if FormulaExpression = '' then
            exit(false);

        if not ParseType(FormulaExpression, Type) then
            exit(false);

        exit(true);
    end;

    local procedure ParseSignedInteger(var FormulaExpression: Code[20]; var Int: Integer): Boolean
    begin
        Int := 0;

        case CopyStr(FormulaExpression, 1, 1) of
            '-':
                begin
                    FormulaExpression := CopyStr(FormulaExpression, 2);
                    if not ParseInt(FormulaExpression, Int, false) then
                        exit(false);
                    Int := -Int;
                end;
            '+':
                begin
                    FormulaExpression := CopyStr(FormulaExpression, 2);
                    if not ParseInt(FormulaExpression, Int, false) then
                        exit(false);
                end;
            else
                if not ParseInt(FormulaExpression, Int, true) then
                    exit(false);
        end;
        exit(true);
    end;

    local procedure ParseInt(var FormulaExpression: Code[20]; var Int: Integer; AllowNotInt: Boolean): Boolean
    var
        IntegerStr: Code[20];
    begin
        if CopyStr(FormulaExpression, 1, 1) in ['1' .. '9'] then
            repeat
                IntegerStr := IntegerStr + CopyStr(FormulaExpression, 1, 1);
                FormulaExpression := CopyStr(FormulaExpression, 2);
                if FormulaExpression = '' then
                    exit(false);
            until not (CopyStr(FormulaExpression, 1, 1) in ['0' .. '9'])
        else
            exit(AllowNotInt);
        Evaluate(Int, IntegerStr);
        exit(true);
    end;

    local procedure ParseType(var FormulaExpression: Code[20]; var Type: Enum "Period Type"): Boolean
    begin
        case ReadToken(FormulaExpression) of
            PeriodTok:
                Type := Type::Period;
            FiscalYearTok:
                Type := Type::"Fiscal Year";
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure ParseRange(var FormulaExpression: Code[20]; var FromType: Enum "Period Formula Range"; var FromInt: Integer; var ToType: Enum "Period Formula Range"; var ToInt: Integer): Boolean
    begin
        FromType := FromType::CP;
        ToType := ToType::CP;

        if FormulaExpression = '' then
            exit(true);

        if not ParseToken(FormulaExpression, '[') then
            exit(false);

        if not ParseIndex(FormulaExpression, FromType, FromInt) then
            exit(false);
        if FormulaExpression = '' then
            exit(false);

        if CopyStr(FormulaExpression, 1, 1) = '.' then begin
            if not ParseToken(FormulaExpression, '..') then
                exit(false);
            if not ParseIndex(FormulaExpression, ToType, ToInt) then
                exit(false);
        end else begin
            ToType := FromType;
            ToInt := FromInt;
        end;

        if not ParseToken(FormulaExpression, ']') then
            exit(false);

        exit(true);
    end;

    local procedure ParseIndex(var FormulaExpression: Code[20]; var IndexType: Enum "Period Formula Range"; var Index: Integer): Boolean
    begin
        if FormulaExpression = '' then
            exit(false);

        if ParseInt(FormulaExpression, Index, false) then
            IndexType := IndexType::Int
        else
            case ReadToken(FormulaExpression) of
                CurrentPeriodTok:
                    IndexType := IndexType::CP;
                LastPeriodTok:
                    IndexType := IndexType::LP;
                else
                    exit(false);
            end;

        exit(true);
    end;

    local procedure ParseToken(var FormulaExpression: Code[20]; Token: Code[20]): Boolean
    begin
        if CopyStr(FormulaExpression, 1, StrLen(Token)) <> Token then
            exit(false);
        FormulaExpression := CopyStr(FormulaExpression, StrLen(Token) + 1);
        exit(true)
    end;

    local procedure ReadToken(var FormulaExpression: Code[20]): Code[20]
    var
        Token: Code[20];
        p: Integer;
    begin
        for p := 1 to StrLen(FormulaExpression) do begin
            if CopyStr(FormulaExpression, p, 1) in ['[', ']', '.'] then begin
                FormulaExpression := CopyStr(FormulaExpression, StrLen(Token) + 1);
                exit(Token);
            end;
            Token := Token + CopyStr(FormulaExpression, p, 1);
        end;

        FormulaExpression := '';
        exit(Token);
    end;

    procedure GetPeriodName(): Code[10]
    begin
        exit(PeriodTok);
    end;
}