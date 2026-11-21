// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.Check;
using Microsoft.Finance.Currency;

/// <summary>
/// Provides the French amount wording for the Check report.
/// French-language sessions use French number grammar and euro/cent wording.
/// Other languages use the international wording with hundredths.
/// </summary>
codeunit 10824 "Check Amount Wording FR"
{
    Access = Public;

    var
        OnesText: array[20] of Text[30];
        TensText: array[10] of Text[30];
        ExponentText: array[5] of Text[30];
        ZeroLbl: Label 'ZERO';
        HundredLbl: Label 'HUNDRED';
        AndLbl: Label 'AND';
        TooLongErr: Label '%1 results in a written number that is too long.', Comment = '%1 = Text that does not fit in the amount wording';
        OneLbl: Label 'ONE';
        TwoLbl: Label 'TWO';
        ThreeLbl: Label 'THREE';
        FourLbl: Label 'FOUR';
        FiveLbl: Label 'FIVE';
        SixLbl: Label 'SIX';
        SevenLbl: Label 'SEVEN';
        EightLbl: Label 'EIGHT';
        NineLbl: Label 'NINE';
        TenLbl: Label 'TEN';
        ElevenLbl: Label 'ELEVEN';
        TwelveLbl: Label 'TWELVE';
        ThirteenLbl: Label 'THIRTEEN';
        FourteenLbl: Label 'FOURTEEN';
        FifteenLbl: Label 'FIFTEEN';
        SixteenLbl: Label 'SIXTEEN';
        SeventeenLbl: Label 'SEVENTEEN';
        EighteenLbl: Label 'EIGHTEEN';
        NineteenLbl: Label 'NINETEEN';
        TwentyLbl: Label 'TWENTY';
        ThirtyLbl: Label 'THIRTY';
        FortyLbl: Label 'FORTY';
        FiftyLbl: Label 'FIFTY';
        SixtyLbl: Label 'SIXTY';
        SeventyLbl: Label 'SEVENTY';
        EightyLbl: Label 'EIGHTY';
        NinetyLbl: Label 'NINETY';
        ThousandLbl: Label 'THOUSAND';
        MillionLbl: Label 'MILLION';
        BillionLbl: Label 'BILLION';
        EurosLbl: Label 'EUROS';
        CentLbl: Label 'CENT';

    [EventSubscriber(ObjectType::Report, Report::Check, 'OnBeforeFormatNoText', '', false, false)]
    local procedure OnBeforeFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
        HandleBeforeFormatNoText(NoText, No, CurrencyCode, IsHandled);
    end;

    internal procedure HandleBeforeFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10]; var IsHandled: Boolean)
#if not CLEAN30
    var
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
#endif
    begin
        if IsHandled then
            exit;

#if not CLEAN30
        if not ReportsFR.IsEnabled(false) then
            exit;
#endif

        if IsFrenchLanguage() then
            FormatNoTextFR(NoText, No, CurrencyCode)
        else
            FormatNoTextINTL(NoText, No, CurrencyCode);

        IsHandled := true;
    end;

    local procedure IsFrenchLanguage(): Boolean
    begin
        exit(GlobalLanguage() in [1036, 2060, 3084, 4108]);
    end;

    local procedure InitTextVariable()
    begin
        Clear(OnesText);
        Clear(TensText);
        Clear(ExponentText);
        OnesText[1] := OneLbl;
        OnesText[2] := TwoLbl;
        OnesText[3] := ThreeLbl;
        OnesText[4] := FourLbl;
        OnesText[5] := FiveLbl;
        OnesText[6] := SixLbl;
        OnesText[7] := SevenLbl;
        OnesText[8] := EightLbl;
        OnesText[9] := NineLbl;
        OnesText[10] := TenLbl;
        OnesText[11] := ElevenLbl;
        OnesText[12] := TwelveLbl;
        OnesText[13] := ThirteenLbl;
        OnesText[14] := FourteenLbl;
        OnesText[15] := FifteenLbl;
        OnesText[16] := SixteenLbl;
        OnesText[17] := SeventeenLbl;
        OnesText[18] := EighteenLbl;
        OnesText[19] := NineteenLbl;

        TensText[1] := '';
        TensText[2] := TwentyLbl;
        TensText[3] := ThirtyLbl;
        TensText[4] := FortyLbl;
        TensText[5] := FiftyLbl;
        TensText[6] := SixtyLbl;
        TensText[7] := SeventyLbl;
        TensText[8] := EightyLbl;
        TensText[9] := NinetyLbl;

        ExponentText[1] := '';
        ExponentText[2] := ThousandLbl;
        ExponentText[3] := MillionLbl;
        ExponentText[4] := BillionLbl;
    end;

    local procedure AddToNoText(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; var PrintExponent: Boolean; AddText: Text[30])
    begin
        PrintExponent := true;

        while StrLen(NoText[NoTextIndex] + ' ' + AddText) > MaxStrLen(NoText[1]) do begin
            NoTextIndex := NoTextIndex + 1;
            if NoTextIndex > ArrayLen(NoText) then
                Error(TooLongErr, AddText);
        end;

        NoText[NoTextIndex] := CopyStr(DelChr(NoText[NoTextIndex] + ' ' + AddText, '<'), 1, MaxStrLen(NoText[NoTextIndex]));
    end;

    /// <summary>
    /// Formats an amount using the legacy French grammar and the current language's labels.
    /// No separate initialization is required.
    /// </summary>
    procedure FormatNoTextFR(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
    begin
        InitTextVariable();
        Clear(NoText);
        NoTextIndex := 1;
        NoText[1] := '****';

        if No < 1 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, ZeroLbl)
        else
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;

                if Hundreds = 1 then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, HundredLbl)
                else
                    if Hundreds > 1 then begin
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds]);
                        if (Tens * 10 + Ones) = 0 then
                            AddToNoText(NoText, NoTextIndex, PrintExponent, HundredLbl + 'S')
                        else
                            AddToNoText(NoText, NoTextIndex, PrintExponent, HundredLbl);
                    end;

                FormatTensInternal(NoText, NoTextIndex, PrintExponent, Exponent, Hundreds, Tens, Ones);

                if PrintExponent and (Exponent > 1) then
                    if ((Hundreds * 100 + Tens * 10 + Ones) > 1) and (Exponent <> 2) then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent] + 'S')
                    else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent]);

                No := No - (Hundreds * 100 + Tens * 10 + Ones) * Power(1000, Exponent - 1);
            end;

        if CurrencyCode = '' then
            AddToNoText(NoText, NoTextIndex, PrintExponent, EurosLbl)
        else begin
            Currency.Get(CurrencyCode);
            AddToNoText(NoText, NoTextIndex, PrintExponent, UpperCase(Currency.Description));
        end;

        No := No * 100;
        Ones := No mod 10;
        Tens := No div 10;
        FormatTensInternal(NoText, NoTextIndex, PrintExponent, Exponent, Hundreds, Tens, Ones);

        if (CurrencyCode = '') or (CurrencyCode = 'FRF') then
            case true of
                No = 1:
                    AddToNoText(NoText, NoTextIndex, PrintExponent, CentLbl);
                No > 1:
                    AddToNoText(NoText, NoTextIndex, PrintExponent, CentLbl + 'S');
            end;
    end;

    /// <summary>
    /// Appends tens using the legacy French grammar and the current language's labels.
    /// Preserves the caller's text, line index and exponent state.
    /// </summary>
    procedure FormatTens(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; var PrintExponent: Boolean; Exponent: Integer; Hundreds: Integer; Tens: Integer; Ones: Integer)
    begin
        InitTextVariable();
        FormatTensInternal(NoText, NoTextIndex, PrintExponent, Exponent, Hundreds, Tens, Ones);
    end;

    local procedure FormatTensInternal(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; var PrintExponent: Boolean; Exponent: Integer; Hundreds: Integer; Tens: Integer; Ones: Integer)
    begin
        case Tens of
            9:
                begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, EightyLbl);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones + 10]);
                end;
            8:
                if Ones = 0 then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, EightyLbl + 'S')
                else begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, EightyLbl);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones]);
                end;
            7:
                begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, SixtyLbl);
                    if Ones = 1 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, AndLbl);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones + 10]);
                end;
            2:
                begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TwentyLbl);
                    if Ones > 0 then begin
                        if Ones = 1 then
                            AddToNoText(NoText, NoTextIndex, PrintExponent, AndLbl);
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones]);
                    end;
                end;
            1:
                AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Tens * 10 + Ones]);
            0:
                if Ones > 0 then
                    if (Ones = 1) and (Hundreds < 1) and (Exponent = 2) then
                        PrintExponent := true
                    else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones]);
            else begin
                AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[Tens]);
                if Ones > 0 then begin
                    if Ones = 1 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, 'ET');
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones]);
                end;
            end;
        end;
    end;

    /// <summary>
    /// Formats an amount using the legacy international grammar and fixed hundredths.
    /// No separate initialization is required.
    /// </summary>
    procedure FormatNoTextINTL(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    var
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
    begin
        InitTextVariable();
        Clear(NoText);
        NoTextIndex := 1;
        NoText[1] := '****';

        if No < 1 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, ZeroLbl)
        else
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;
                if Hundreds > 0 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds]);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, HundredLbl);
                end;
                if Tens >= 2 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[Tens]);
                    if Ones > 0 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones]);
                end else
                    if (Tens * 10 + Ones) > 0 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Tens * 10 + Ones]);
                if PrintExponent and (Exponent > 1) then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent]);
                No := No - (Hundreds * 100 + Tens * 10 + Ones) * Power(1000, Exponent - 1);
            end;

        AddToNoText(NoText, NoTextIndex, PrintExponent, AndLbl);
        AddToNoText(NoText, NoTextIndex, PrintExponent, Format(No * 100) + '/100');

        if CurrencyCode <> '' then
            AddToNoText(NoText, NoTextIndex, PrintExponent, CurrencyCode);
    end;
}
