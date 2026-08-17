// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using Microsoft.Inventory.Setup;
using System.Text;

codeunit 360 "Accounting Period Mgt."
{
    Permissions = tabledata "Accounting Period" = R;

    trigger OnRun()
    begin
    end;

    var
        PeriodTxt: Label 'PERIOD', Comment = 'Must be uppercase. Reuse the translation from COD1 for 2009 SP1.';
        YearTxt: Label 'YEAR', Comment = 'Must be uppercase. Reuse the translation from COD1 for 2009 SP1.';
        NumeralTxt: Label '0123456789', Comment = 'Numerals';
        ReservedCharsTxt: Label '-+|. ', Locked = true;
        CombineTok: Label '%1%2', Locked = true;
        NumeralOutOfRangeErr: Label 'When you specify periods and years, you can use numbers from 1 - 999, such as P-1, P1, Y2 or Y+3.';

    procedure GetPeriodStartingDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetCurrentKey(Closed);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            exit(AccountingPeriod."Starting Date");
        exit(CalcDate('<-CY>', WorkDate()));
    end;

    procedure CheckPostingDateInFiscalYear(PostingDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then
            exit;
        AccountingPeriod.Get(NormalDate(PostingDate) + 1);
        AccountingPeriod.TestField("New Fiscal Year", true);
        AccountingPeriod.TestField("Date Locked", true);
    end;

    procedure FindFiscalYear(BalanceDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then begin
            if BalanceDate = 0D then
                exit(CalcDate('<-CY>', WorkDate()));
            exit(CalcDate('<-CY>', BalanceDate));
        end;
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Starting Date", 0D, BalanceDate);
        if AccountingPeriod.FindLast() then
            exit(AccountingPeriod."Starting Date");
        AccountingPeriod.Reset();
        AccountingPeriod.FindFirst();
        exit(AccountingPeriod."Starting Date");
    end;

    procedure FindEndOfFiscalYear(BalanceDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then begin
            if BalanceDate = 0D then
                exit(CalcDate('<CY>', WorkDate()));
            exit(CalcDate('<CY>', BalanceDate));
        end;
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '>%1', FindFiscalYear(BalanceDate));
        if AccountingPeriod.FindFirst() then
            exit(CalcDate('<-1D>', AccountingPeriod."Starting Date"));
        exit(DMY2Date(31, 12, 9999));
    end;

    procedure AccPeriodStartEnd(Date: Date; var StartDate: Date; var EndDate: Date; var PeriodError: Boolean; Steps: Integer; Type: Enum "Period Type"; RangeFromType: Enum "Period Formula Range"; RangeToType: Enum "Period Formula Range"; RangeFromInt: Integer; RangeToInt: Integer)
    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriodFY: Record "Accounting Period";
        CurrentPeriodNo: Integer;
    begin
        AccountingPeriod.SetFilter("Starting Date", '<=%1', Date);
        if not AccountingPeriod.FindLast() then begin
            AccountingPeriod.Reset();
            if Steps < 0 then
                AccountingPeriod.FindFirst()
            else
                AccountingPeriod.FindLast()
        end;
        AccountingPeriod.Reset();

        case Type of
            Type::Period:
                begin
                    if AccountingPeriod.Next(Steps) <> Steps then
                        PeriodError := true;
                    StartDate := AccountingPeriod."Starting Date";
                    EndDate := AccPeriodEndDate(StartDate);
                end;
            Type::"Fiscal Year":
                begin
                    AccountingPeriodFY := AccountingPeriod;
                    while not AccountingPeriodFY."New Fiscal Year" do
                        if AccountingPeriodFY.Find('<') then
                            CurrentPeriodNo += 1
                        else
                            AccountingPeriodFY."New Fiscal Year" := true;
                    AccountingPeriodFY.SetRange("New Fiscal Year", true);
                    AccountingPeriodFY.Next(Steps);

                    AccPeriodStartOrEnd(AccountingPeriodFY, CurrentPeriodNo, RangeFromType, RangeFromInt, false, StartDate);
                    AccPeriodStartOrEnd(AccountingPeriodFY, CurrentPeriodNo, RangeToType, RangeToInt, true, EndDate);
                end;
        end;
    end;

    procedure AccPeriodEndDate(StartDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty() then
            exit(CalcDate('<CY>', StartDate));
        AccountingPeriod."Starting Date" := StartDate;
        if AccountingPeriod.Find('>') then
            exit(AccountingPeriod."Starting Date" - 1);
        exit(DMY2Date(31, 12, 9999));
    end;

    procedure AccPeriodStartOrEnd(AccountingPeriod: Record "Accounting Period"; CurrentPeriodNo: Integer; RangeType: Enum "Period Formula Range"; RangeInt: Integer; EndDate: Boolean; var Date: Date)
    begin
        case RangeType of
            RangeType::CP:
                AccPeriodGetPeriod(AccountingPeriod, CurrentPeriodNo);
            RangeType::LP:
                AccPeriodGetPeriod(AccountingPeriod, -1);
            RangeType::Int:
                AccPeriodGetPeriod(AccountingPeriod, RangeInt - 1);
        end;
        if EndDate then
            Date := AccPeriodEndDate(AccountingPeriod."Starting Date")
        else
            Date := AccountingPeriod."Starting Date";
    end;

    local procedure AccPeriodGetPeriod(var AccountingPeriod: Record "Accounting Period"; AccPeriodNo: Integer)
    begin
        case true of
            AccPeriodNo > 0:
                begin
                    AccountingPeriod.Next(AccPeriodNo);
                    exit;
                end;
            AccPeriodNo = 0:
                exit;
            AccPeriodNo < 0:
                begin
                    AccountingPeriod.SetRange("New Fiscal Year", true);
                    if not AccountingPeriod.Find('>') then begin
                        AccountingPeriod.Reset();
                        AccountingPeriod.Find('+');
                        exit;
                    end;
                    AccountingPeriod.Reset();
                    AccountingPeriod.Find('<');
                    exit;
                end;
        end;
    end;

    procedure InitStartYearAccountingPeriod(var AccountingPeriod: Record "Accounting Period"; PostingDate: Date)
    begin
        InitAccountingPeriod(AccountingPeriod, CalcDate('<-CY>', PostingDate), true);
    end;

    procedure InitDefaultAccountingPeriod(var AccountingPeriod: Record "Accounting Period"; PostingDate: Date)
    begin
        InitAccountingPeriod(AccountingPeriod, CalcDate('<-CM>', PostingDate), false);
    end;

    local procedure InitAccountingPeriod(var AccountingPeriod: Record "Accounting Period"; StartingDate: Date; NewFiscalYear: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := CalcDate('<-CM>', StartingDate);
        AccountingPeriod.Name := Format(AccountingPeriod."Starting Date", 0, '<Month Text,10>');
        AccountingPeriod."New Fiscal Year" := NewFiscalYear;
        if NewFiscalYear then begin
            InventorySetup.Get();
            AccountingPeriod."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type";
            AccountingPeriod."Average Cost Period" := InventorySetup."Average Cost Period";
        end;
    end;

    procedure GetDefaultPeriodEndingDate(PostingDate: Date): Date
    begin
        exit(CalcDate('<CM>', PostingDate));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Tokens", 'OnResolveDateFilterToken', '', false, false)]
    local procedure OnResolveDateFilterToken(DateToken: Text; var FromDate: Date; var ToDate: Date; var Handled: Boolean)
    var
        TextToken: Text;
        Position: Integer;
    begin
        Position := 1;
        FindText(TextToken, DateToken, Position);
        Position := Position + StrLen(TextToken);
        case TextToken of
            CopyStr('PERIOD', 1, StrLen(TextToken)), CopyStr(PeriodTxt, 1, StrLen(TextToken)):
                Handled := FindPeriod(FromDate, ToDate, false, TextToken, DateToken, Position);
            CopyStr('YEAR', 1, StrLen(TextToken)), CopyStr(YearTxt, 1, StrLen(TextToken)):
                Handled := FindPeriod(FromDate, ToDate, true, TextToken, DateToken, Position);
        end;
    end;

    local procedure FindPeriod(var Date1: Date; var Date2: Date; FindYear: Boolean; PartOfText: Text; DateToken: Text; Position: Integer): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        Sign: Text[1];
        Numeral: Integer;
    begin
        GetPositionDifferentCharacter(' ', DateToken, Position);

        if AccountingPeriod.IsEmpty() then begin
            if FindYear then
                AccountingPeriodMgt.InitStartYearAccountingPeriod(AccountingPeriod, WorkDate())
            else
                AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, WorkDate());
            ReadNumeral(Numeral, DateToken, Position);
            Date1 := AccountingPeriod."Starting Date";
            Date2 := CalcDate('<CY>', AccountingPeriod."Starting Date");
            GetPositionDifferentCharacter(' ', PartOfText, Position);
            exit(true);
        end;

        if FindYear then
            AccountingPeriod.SetRange("New Fiscal Year", true)
        else
            AccountingPeriod.SetRange("New Fiscal Year");
        Sign := '';
        if ReadSymbol('+', DateToken, Position) then
            Sign := '+'
        else
            if ReadSymbol('-', DateToken, Position) then
                Sign := '-';
        if Sign = '' then
            if ReadNumeral(Numeral, DateToken, Position) then begin
                if FindYear then
                    AccountingPeriod.FindFirst()
                else begin
                    AccountingPeriod.SetRange("New Fiscal Year", true);
                    AccountingPeriod."Starting Date" := WorkDate();
                    AccountingPeriod.Find('=<');
                    AccountingPeriod.SetRange("New Fiscal Year");
                end;
                AccountingPeriod.Next(Numeral - 1);
            end else begin
                AccountingPeriod."Starting Date" := WorkDate();
                AccountingPeriod.Find('=<');
            end
        else begin
            if not ReadNumeral(Numeral, DateToken, Position) then
                exit(true);
            if Sign = '-' then
                Numeral := -Numeral;
            AccountingPeriod."Starting Date" := WorkDate();
            AccountingPeriod.Find('=<');
            AccountingPeriod.Next(Numeral);
        end;
        Date1 := AccountingPeriod."Starting Date";
        if AccountingPeriod.Next() = 0 then
            Date2 := DMY2Date(31, 12, 9999)
        else
            Date2 := AccountingPeriod."Starting Date" - 1;
        exit(true);
    end;

    local procedure ReadSymbol(Token: Text[30]; Text: Text; var Position: Integer): Boolean
    begin
        if Token <> CopyStr(Text, Position, StrLen(Token)) then
            exit(false);
        Position := Position + StrLen(Token);
        GetPositionDifferentCharacter(' ', Text, Position);
        exit(true);
    end;

    local procedure ReadNumeral(var Numeral: Integer; Text: Text; var Position: Integer): Boolean
    var
        Position2: Integer;
        i: Integer;
    begin
        Position2 := Position;
        GetPositionDifferentCharacter(NumeralTxt, Text, Position);
        if Position2 = Position then
            exit(false);
        Numeral := 0;
        for i := Position2 to Position - 1 do
            if Numeral < 1000 then
                Numeral := Numeral * 10 + StrPos(NumeralTxt, CopyStr(Text, i, 1)) - 1;
        if (Numeral < 1) or (Numeral > 999) then
            Error(NumeralOutOfRangeErr);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetPositionDifferentCharacter(Character: Text[50]; Text: Text; var Position: Integer)
    var
        Length: Integer;
    begin
        Length := StrLen(Text);
        while (Position <= Length) and (StrPos(Character, UpperCase(CopyStr(Text, Position, 1))) <> 0) do
            Position := Position + 1;
    end;

    [Scope('OnPrem')]
    procedure GetPositionMatchingCharacter(Character: Text[50]; Text: Text; var Position: Integer)
    var
        Length: Integer;
    begin
        Length := StrLen(Text);
        while (Position <= Length) and (StrPos(Character, UpperCase(CopyStr(Text, Position, 1))) = 0) do
            Position := Position + 1;
    end;

    [Scope('OnPrem')]
    procedure FindText(var PartOfText: Text; Text: Text; Position: Integer): Boolean
    var
        Position2: Integer;
    begin
        Position2 := Position;
        GetPositionMatchingCharacter(StrSubstNo(CombineTok, NumeralTxt, ReservedCharsTxt), Text, Position);
        if Position = Position2 then
            exit(false);
        PartOfText := UpperCase(CopyStr(Text, Position2, Position - Position2));
        exit(true);
    end;
}

