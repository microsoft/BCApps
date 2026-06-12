// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

codeunit 28020 "Report Management APAC"
{

    trigger OnRun()
    begin
    end;

    var
        OnesText: array[20] of Text[30];
        TensText: array[10] of Text[30];
        ExponentText: array[5] of Text[30];
        MustBePositiveErr: Label '%1 must be positive.', Comment = '%1 - amount in text';
#pragma warning disable AA0074
        Text001: Label 'Amounts are in whole 10s';
        Text002: Label 'Amounts are in whole 100s';
        Text003: Label 'Amounts are in whole 1,000s';
        Text004: Label 'Amounts are in whole 100,000s';
        Text005: Label 'Amounts are in whole 1,000,000s';
        Text006: Label 'Amounts are not rounded';
        Text1500000: Label 'ONE';
        Text1500001: Label 'TWO';
        Text1500002: Label 'THREE';
        Text1500003: Label 'FOUR';
        Text1500004: Label 'FIVE';
        Text1500005: Label 'SIX';
        Text1500006: Label 'SEVEN';
        Text1500007: Label 'EIGHT';
        Text1500008: Label 'NINE';
        Text1500009: Label 'TEN';
        Text1500010: Label 'ELEVEN';
        Text1500011: Label 'TWELVE';
        Text1500012: Label 'THIRTEEN';
        Text1500013: Label 'FOURTEEN';
        Text1500014: Label 'FIFTEEN';
        Text1500015: Label 'SIXTEEN';
        Text1500016: Label 'SEVENTEEN';
        Text1500017: Label 'EIGHTEEN';
        Text1500018: Label 'NINETEEN';
        Text1500019: Label 'TWENTY';
        Text1500020: Label 'THIRTY';
        Text1500021: Label 'FORTY';
        Text1500022: Label 'FIFTY';
        Text1500023: Label 'SIXTY';
        Text1500024: Label 'SEVENTY';
        Text1500025: Label 'EIGHTY';
        Text1500026: Label 'NINETY';
        Text1500027: Label 'THOUSAND';
        Text1500028: Label 'MILLION';
        Text1500029: Label 'BILLION';
        Text1500030: Label 'NUENG';
        Text1500031: Label 'SAWNG';
        Text1500032: Label 'SARM';
        Text1500033: Label 'SI';
        Text1500034: Label 'HA';
        Text1500035: Label 'HOK';
        Text1500036: Label 'CHED';
        Text1500037: Label 'PAED';
        Text1500038: Label 'KOW';
        Text1500039: Label 'SIB';
        Text1500040: Label 'SIB-ED';
        Text1500041: Label 'SIB-SAWNG';
        Text1500042: Label 'SIB-SARM';
        Text1500043: Label 'SIB-SI';
        Text1500044: Label 'SIB-HA';
        Text1500045: Label 'SIB-HOK';
        Text1500046: Label 'SIB-CHED';
        Text1500047: Label 'SIB-PAED';
        Text1500048: Label 'SIB-KOW';
        Text1500049: Label 'YI-SIB';
        Text1500050: Label 'SARM-SIB';
        Text1500051: Label 'SI-SIB';
        Text1500052: Label 'HA-SIB';
        Text1500053: Label 'HOK-SIB';
        Text1500054: Label 'CHED-SIB';
        Text1500055: Label 'PAED-SIB';
        Text1500056: Label 'KOW-SIB';
        Text1500057: Label 'PHAN';
        Text1500058: Label 'LAAN?';
        Text1500059: Label 'PHAN-LAAN?';
        Text1500060: Label 'HUNDRED';
        Text1500061: Label 'ZERO';
        Text1500062: Label 'AND';
#pragma warning restore AA0074

    procedure RoundAmount(Amount: Decimal; Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions): Decimal
    begin
        case Rounding of
            Rounding::" ":
                exit(Amount);
            Rounding::Tens:
                exit(Round(Amount / 10, 0.1));
            Rounding::Hundreds:
                exit(Round(Amount / 100, 0.1));
            Rounding::Thousands:
                exit(Round(Amount / 1000, 1));
            Rounding::"Hundred Thousands":
                exit(Round(Amount / 100000, 0.1));
            Rounding::Millions:
                exit(Round(Amount / 1000000, 0.1));
        end;
    end;

    procedure RoundDescription(Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions): Text[50]
    begin
        case Rounding of
            Rounding::" ":
                exit(Text006);
            Rounding::Tens:
                exit(Text001);
            Rounding::Hundreds:
                exit(Text002);
            Rounding::Thousands:
                exit(Text003);
            Rounding::"Hundred Thousands":
                exit(Text004);
            Rounding::Millions:
                exit(Text005);
        end;
    end;

    /// <summary>
    /// Initializes text variables for number-to-text conversion in English.
    /// </summary>
    procedure InitTextVariable()
    begin
        OnesText[1] := Text1500000;
        OnesText[2] := Text1500001;
        OnesText[3] := Text1500002;
        OnesText[4] := Text1500003;
        OnesText[5] := Text1500004;
        OnesText[6] := Text1500005;
        OnesText[7] := Text1500006;
        OnesText[8] := Text1500007;
        OnesText[9] := Text1500008;
        OnesText[10] := Text1500009;
        OnesText[11] := Text1500010;
        OnesText[12] := Text1500011;
        OnesText[13] := Text1500012;
        OnesText[14] := Text1500013;
        OnesText[15] := Text1500014;
        OnesText[16] := Text1500015;
        OnesText[17] := Text1500016;
        OnesText[18] := Text1500017;
        OnesText[19] := Text1500018;

        TensText[1] := '';
        TensText[2] := Text1500019;
        TensText[3] := Text1500020;
        TensText[4] := Text1500021;
        TensText[5] := Text1500022;
        TensText[6] := Text1500023;
        TensText[7] := Text1500024;
        TensText[8] := Text1500025;
        TensText[9] := Text1500026;

        ExponentText[1] := '';
        ExponentText[2] := Text1500027;
        ExponentText[3] := Text1500028;
        ExponentText[4] := Text1500029;
    end;

    procedure InitTextVariableTH()
    begin
        OnesText[1] := Text1500030;
        OnesText[2] := Text1500031;
        OnesText[3] := Text1500032;
        OnesText[4] := Text1500033;
        OnesText[5] := Text1500034;
        OnesText[6] := Text1500035;
        OnesText[7] := Text1500036;
        OnesText[8] := Text1500037;
        OnesText[9] := Text1500038;
        OnesText[10] := Text1500039;
        OnesText[11] := Text1500040;
        OnesText[12] := Text1500041;
        OnesText[13] := Text1500042;
        OnesText[14] := Text1500043;
        OnesText[15] := Text1500044;
        OnesText[16] := Text1500045;
        OnesText[17] := Text1500046;
        OnesText[18] := Text1500047;
        OnesText[19] := Text1500048;

        TensText[1] := '';
        TensText[2] := Text1500049;
        TensText[3] := Text1500050;
        TensText[4] := Text1500051;
        TensText[5] := Text1500052;
        TensText[6] := Text1500053;
        TensText[7] := Text1500054;
        TensText[8] := Text1500055;
        TensText[9] := Text1500056;

        ExponentText[1] := '';
        ExponentText[2] := Text1500057;
        ExponentText[3] := Text1500058;
        ExponentText[4] := Text1500059;
    end;

    /// <summary>
    /// Formats a decimal number as text in English words.
    /// </summary>
    /// <param name="NoText">The output array receiving the formatted text.</param>
    /// <param name="No">The decimal number to format.</param>
    /// <param name="CurrencyCode">The currency code to append, if not empty.</param>
    procedure FormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
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
            AddToNoText(NoText, NoTextIndex, PrintExponent, Text1500061)
        else
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;
                if Hundreds > 0 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds]);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, Text1500060);
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

        AddToNoText(NoText, NoTextIndex, PrintExponent, Text1500062);
        AddToNoText(NoText, NoTextIndex, PrintExponent, Format(No * 100) + '/100');

        if CurrencyCode <> '' then
            AddToNoText(NoText, NoTextIndex, PrintExponent, CurrencyCode);
    end;

    procedure FormatNoTextTH(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    var
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
    begin
        InitTextVariableTH();

        Clear(NoText);
        NoTextIndex := 1;
        NoText[1] := '****';

        if No < 1 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, Text1500061)
        else
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;
                if Hundreds > 0 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds]);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, Text1500060);
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

        AddToNoText(NoText, NoTextIndex, PrintExponent, Text1500062);
        AddToNoText(NoText, NoTextIndex, PrintExponent, Format(No * 100) + '/100');

        if CurrencyCode <> '' then
            AddToNoText(NoText, NoTextIndex, PrintExponent, CurrencyCode);
    end;

    local procedure AddToNoText(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; var PrintExponent: Boolean; AddText: Text[30])
    begin
        PrintExponent := true;

        while StrLen(NoText[NoTextIndex] + ' ' + AddText) > MaxStrLen(NoText[1]) do begin
            NoTextIndex := NoTextIndex + 1;
            if NoTextIndex > ArrayLen(NoText) then
                Error(MustBePositiveErr, AddText);
        end;

        NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + ' ' + AddText, '<');
    end;
}
