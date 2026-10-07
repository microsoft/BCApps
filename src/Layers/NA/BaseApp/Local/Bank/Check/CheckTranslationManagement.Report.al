// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using System.Globalization;
using System.Utilities;

report 10400 "Check Translation Management"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Check/CheckTranslationManagement.rdlc';
    Caption = 'Test Check Translation Management Functions';

    dataset
    {
        dataitem(PageLoop; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(TestLanguage; TestLanguage)
            {
                OptionCaption = 'ENU,ENC,FRC,ESM';
                OptionMembers = ENU,ENC,FRC,ESM;
            }
            column(TestCurrencyCode; TestCurrencyCode)
            {
            }
            column(TestDate; TestDate)
            {
            }
            column(CheckTransFunctionsCaption; CheckTranslationFunctionsCaptionLbl)
            {
            }
            column(TestDateCaption; TestDateCaptionLbl)
            {
            }
            column(TestLanguageCaption; TestLanguageCaptionLbl)
            {
            }
            column(TestCurrencyCodeCaption; TestCurrencyCodeCaptionLbl)
            {
            }
            column(DateToTestCaption; DateToTestCaptionLbl)
            {
            }
            dataitem(AmountTestLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(TestAmountText1; TestAmountText[1])
                {
                }
                column(TestAmountText2; TestAmountText[2])
                {
                }
                column(AmountInWordsCaption; AmountInWordsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not FormatNoText(TestAmountText, TestAmount[Number], TestLanguageCode, TestCurrencyCode) then
                        TestAmountText[1] := 'ERROR:  ' + TestAmountText[1];
                end;

                trigger OnPreDataItem()
                begin
                    if TestOption = TestOption::"Dates Only" then
                        CurrReport.Break();
                    SetRange(Number, 1, TestNumAmounts);
                end;
            }
            dataitem(DateTestLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(TestDateIndicator; TestDateIndicator)
                {
                }
                column(TestDateText; TestDateText)
                {
                }
                column(TestDateSeparatorFormatted; Format(TestDateSeparator[Number]))
                {
                }
                column(TestDateIndicatorCaption; TestDateIndicatorCaptionLbl)
                {
                }
                column(TestDateTextCaption; TestDateTextCaptionLbl)
                {
                }
                column(DateSeparatorCaption; DateSeparatorCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TestDateText :=
                      FormatDate(TestDate, TestDateFormat[Number], TestDateSeparator[Number], TestLanguageCode, TestDateIndicator);
                end;

                trigger OnPreDataItem()
                begin
                    if TestOption = TestOption::"Amounts Only" then
                        CurrReport.Break();
                    SetRange(Number, 1, TestNumDates);
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(TestOption; TestOption)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Option';
                        OptionCaption = 'Both Amounts and Dates,Amounts Only,Dates Only';
                        ToolTip = 'Specifies what is tested. You can select to test amounts, dates, or both.';
                    }
                    field(TestLanguage; TestLanguage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Language';
                        OptionCaption = 'ENU,ENC,FRC,ESM';
                        ToolTip = 'Specifies the language that you want to test.';
                    }
                    field(TestCurrencyCode; TestCurrencyCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Test Currency Code';
                        TableRelation = Currency;
                        ToolTip = 'Specifies the currency that you want to test.';
                    }
                    field(TestDate; TestDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date to Test';
                        ToolTip = 'Specifies the date when you want to test check translations.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            TestDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        MakeTestData();
        case TestLanguage of
            TestLanguage::ENU:
                TestLanguageCode := 1033;
            TestLanguage::FRC:
                TestLanguageCode := 3084;
            TestLanguage::ESM:
                TestLanguageCode := 2058;
            TestLanguage::ENC:
                TestLanguageCode := 4105;
        end;
    end;

    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        EnglishLanguageCode: Integer;
        FrenchLanguageCode: Integer;
        SpanishLanguageCode: Integer;
        CAEnglishLanguageCode: Integer;
        LanguageCode: Integer;
        CurrencyCode: Code[10];
        OnesText: array[30] of Text[30];
        TensText: array[10] of Text[30];
        HundredsText: array[10] of Text[30];
        ExponentText: array[5] of Text[30];
        HundredText: Text[30];
        AndText: Text[30];
        ZeroText: Text[30];
        CentsText: Text[30];
        OneMillionText: Text[30];
        Text000: Label 'Zero';
        Text001: Label 'One';
        Text002: Label 'Two';
        Text003: Label 'Three';
        Text004: Label 'Four';
        Text005: Label 'Five';
        Text006: Label 'Six';
        Text007: Label 'Seven';
        Text008: Label 'Eight';
        Text009: Label 'Nine';
        Text010: Label 'Ten';
        Text011: Label 'Eleven';
        Text012: Label 'Twelve';
        Text013: Label 'Thirteen';
        Text014: Label 'Fourteen';
        Text015: Label 'Fifteen';
        Text016: Label 'Sixteen';
        Text017: Label 'Seventeen';
        Text018: Label 'Eighteen';
        Text019: Label 'Nineteen';
        Text020: Label 'Twenty';
        Text021: Label 'Thirty';
        Text022: Label 'Forty';
        Text023: Label 'Fifty';
        Text024: Label 'Sixty';
        Text025: Label 'Seventy';
        Text026: Label 'Eighty';
        Text027: Label 'Ninety';
        Text028: Label 'Hundred';
        Text029: Label 'and';
        Text031: Label 'Thousand';
        Text032: Label 'Million';
        Text033: Label 'Billion';
        Text035: Label '/100';
        Text036: Label 'One Million';
        Text041: Label 'Twenty One';
        Text042: Label 'Twenty Two';
        Text043: Label 'Twenty Three';
        Text044: Label 'Twenty Four';
        Text045: Label 'Twenty Five';
        Text046: Label 'Twenty Six';
        Text047: Label 'Twenty Seven';
        Text048: Label 'Twenty Eight';
        Text049: Label 'Twenty Nine';
        Text051: Label 'One Hundred';
        Text052: Label 'Two Hundred';
        Text053: Label 'Three Hundred';
        Text054: Label 'Four Hundred';
        Text055: Label 'Five Hundred';
        Text056: Label 'Six Hundred';
        Text057: Label 'Seven Hundred';
        Text058: Label 'Eight Hundred';
        Text059: Label 'Nine Hundred';
        Text100: Label 'Language Code %1 is not implemented.';
        Text101: Label '%1 results in a written number that is too long.';
        Text102: Label '%1 is too large to convert to text.';
        Text103: Label '%1 language is not enabled.';
        Text104: Label '****';
        Text107: Label 'MM DD YYYY';
        Text108: Label 'DD MM YYYY';
        Text109: Label 'YYYY MM DD';
        TestLanguage: Option ENU,ENC,FRC,ESM;
        TestOption: Option "Both Amounts and Dates","Amounts Only","Dates Only";
        TestCurrencyCode: Code[10];
        TestLanguageCode: Integer;
        TestAmount: array[50] of Decimal;
        TestDateFormat: array[20] of Option " ","MM DD YYYY","DD MM YYYY","YYYY MM DD";
        TestDateSeparator: array[20] of Option " ","-",".","/";
        TestAmountText: array[2] of Text[80];
        TestDateText: Text[30];
        TestDateIndicator: Text[30];
        TestNumAmounts: Integer;
        TestNumDates: Integer;
        TestDate: Date;
        Text110: Label 'US dollars';
        Text111: Label 'Mexican pesos';
        Text112: Label 'Canadian dollars';
        CheckTranslationFunctionsCaptionLbl: Label 'Test of Check Translation Functions';
        TestDateCaptionLbl: Label 'Test Date';
        TestLanguageCaptionLbl: Label 'Test Language';
        TestCurrencyCodeCaptionLbl: Label 'Test Currency Code';
        DateToTestCaptionLbl: Label 'Date to Test';
        AmountInWordsCaptionLbl: Label 'Amount In Words';
        TestDateIndicatorCaptionLbl: Label 'Check Date Indicator';
        TestDateTextCaptionLbl: Label 'Check Date';
        DateSeparatorCaptionLbl: Label 'Check Date Separator';
        USTextErr: Label '%1 language is not enabled. %2 is set up for checks in %1.', Comment = 'English language is not enabled. Bank of America is set up for checks in English.';

    procedure FormatNoText(var NoText: array[2] of Text[80]; No: Decimal; NewLanguageCode: Integer; NewCurrencyCode: Code[10]) Result: Boolean
    begin
        SetObjectLanguage(NewLanguageCode);

        InitTextVariable();
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        CurrencyCode := NewCurrencyCode;
        if CurrencyCode = '' then begin
            Currency.Init();
            Currency.Code := GLSetup."LCY Code";
            case GLSetup."LCY Code" of
                'USD':
                    Currency.Description := Text110;
                'MXP':
                    Currency.Description := Text111;
                'CAD':
                    Currency.Description := Text112;
            end;
        end else
            if not Currency.Get(CurrencyCode) then
                Clear(Currency);
        Clear(NoText);

        if No < 1000000000000.0 then
            case LanguageCode of
                EnglishLanguageCode, CAEnglishLanguageCode:
                    Result := FormatNoTextENU(NoText, No);
                SpanishLanguageCode:
                    Result := FormatNoTextESM(NoText, No);
                FrenchLanguageCode:
                    Result := FormatNoTextFRC(NoText, No);
                else begin
                    NoText[1] := StrSubstNo(Text100, LanguageCode);
                    Result := false;
                end;
            end
        else begin
            NoText[1] := StrSubstNo(Text102, No);
            Result := false;
        end;
    end;

    local procedure SetObjectLanguage(NewLanguageCode: Integer)
    var
        WindowsLang: Record "Windows Language";
    begin
        EnglishLanguageCode := 1033;
        FrenchLanguageCode := 3084;
        SpanishLanguageCode := 2058;
        CAEnglishLanguageCode := 4105;

        WindowsLang.Get(NewLanguageCode);
        if not WindowsLang."Globally Enabled" then
            Error(Text103, WindowsLang.Name);
        LanguageCode := NewLanguageCode;
        CurrReport.Language(LanguageCode);
    end;

    local procedure InitTextVariable()
    begin
        OnesText[1] := Text001;
        OnesText[2] := Text002;
        OnesText[3] := Text003;
        OnesText[4] := Text004;
        OnesText[5] := Text005;
        OnesText[6] := Text006;
        OnesText[7] := Text007;
        OnesText[8] := Text008;
        OnesText[9] := Text009;
        OnesText[10] := Text010;
        OnesText[11] := Text011;
        OnesText[12] := Text012;
        OnesText[13] := Text013;
        OnesText[14] := Text014;
        OnesText[15] := Text015;
        OnesText[16] := Text016;
        OnesText[17] := Text017;
        OnesText[18] := Text018;
        OnesText[19] := Text019;
        OnesText[20] := Text020;
        OnesText[21] := Text041;
        OnesText[22] := Text042;
        OnesText[23] := Text043;
        OnesText[24] := Text044;
        OnesText[25] := Text045;
        OnesText[26] := Text046;
        OnesText[27] := Text047;
        OnesText[28] := Text048;
        OnesText[29] := Text049;

        TensText[1] := Text010;
        TensText[2] := Text020;
        TensText[3] := Text021;
        TensText[4] := Text022;
        TensText[5] := Text023;
        TensText[6] := Text024;
        TensText[7] := Text025;
        TensText[8] := Text026;
        TensText[9] := Text027;

        HundredsText[1] := Text051;
        HundredsText[2] := Text052;
        HundredsText[3] := Text053;
        HundredsText[4] := Text054;
        HundredsText[5] := Text055;
        HundredsText[6] := Text056;
        HundredsText[7] := Text057;
        HundredsText[8] := Text058;
        HundredsText[9] := Text059;

        ExponentText[1] := '';
        ExponentText[2] := Text031;
        ExponentText[3] := Text032;
        ExponentText[4] := Text033;

        HundredText := Text028;
        AndText := Text029;
        ZeroText := Text000;
        CentsText := Text035;
        OneMillionText := Text036;
    end;

    local procedure AddToNoText(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; var PrintExponent: Boolean; AddText: Text[40]; Divider: Text[1]): Boolean
    begin
        if NoTextIndex > ArrayLen(NoText) then
            exit(false);
        PrintExponent := true;

        while StrLen(NoText[NoTextIndex] + ' ' + AddText) > MaxStrLen(NoText[1]) do begin
            NoTextIndex := NoTextIndex + 1;
            if NoTextIndex > ArrayLen(NoText) then begin
                NoText[ArrayLen(NoText)] := StrSubstNo(Text101, AddText);
                exit(false);
            end;
        end;

        case LanguageCode of
            EnglishLanguageCode:
                if NoText[NoTextIndex] = Text104 then
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + UpperCase(AddText), '<')
                else
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + Divider + UpperCase(AddText), '<');
            SpanishLanguageCode:
                if NoText[NoTextIndex] = Text104 then
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + UpperCase(AddText), '<')
                else
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + Divider + UpperCase(AddText), '<');
            CAEnglishLanguageCode:
                if NoText[NoTextIndex] = Text104 then
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + AddText, '<')
                else
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + Divider + AddText, '<');
            FrenchLanguageCode:
                if NoText[NoTextIndex] = Text104 then
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + AddText, '<')
                else
                    NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + Divider + LowerCase(AddText), '<');
        end;

        exit(true);
    end;

    procedure FormatDate(Date: Date; DateFormat: Option " ","MM DD YYYY","DD MM YYYY","YYYY MM DD"; DateSeparator: Option " ","-",".","/"; NewLanguageCode: Integer; var DateIndicator: Text) ChequeDate: Text[30]
    begin
        SetObjectLanguage(NewLanguageCode);

        case DateFormat of
            DateFormat::"MM DD YYYY":
                begin
                    DateIndicator := Text107;
                    case DateSeparator of
                        0:
                            ChequeDate := Format(Date, 0, '<Month,2> <Day,2> <Year4>');
                        1:
                            ChequeDate := Format(Date, 0, '<Month,2>-<Day,2>-<Year4>');
                        2:
                            ChequeDate := Format(Date, 0, '<Month,2>.<Day,2>.<Year4>');
                        3:
                            ChequeDate := Format(Date, 0, '<Month,2>/<Day,2>/<Year4>');
                    end;
                end;
            DateFormat::"DD MM YYYY":
                begin
                    DateIndicator := Text108;
                    case DateSeparator of
                        0:
                            ChequeDate := Format(Date, 0, '<Day,2> <Month,2> <Year4>');
                        1:
                            ChequeDate := Format(Date, 0, '<Day,2>-<Month,2>-<Year4>');
                        2:
                            ChequeDate := Format(Date, 0, '<Day,2>.<Month,2>.<Year4>');
                        3:
                            ChequeDate := Format(Date, 0, '<Day,2>/<Month,2>/<Year4>');
                    end;
                end;
            DateFormat::"YYYY MM DD":
                begin
                    DateIndicator := Text109;
                    case DateSeparator of
                        0:
                            ChequeDate := Format(Date, 0, '<Year4> <Month,2> <Day,2>');
                        1:
                            ChequeDate := Format(Date, 0, '<Year4>-<Month,2>-<Day,2>');
                        2:
                            ChequeDate := Format(Date, 0, '<Year4>.<Month,2>.<Day,2>');
                        3:
                            ChequeDate := Format(Date, 0, '<Year4>/<Month,2>/<Day,2>');
                    end;
                end;
            else begin
                DateIndicator := '';
                ChequeDate := Format(Date, 0, 4);
            end;
        end;
    end;

    local procedure FormatNoTextENU(var NoText: array[2] of Text[80]; No: Decimal): Boolean
    var
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
        CentsAndCurrency: Text[40];
    begin
        NoTextIndex := 1;
        NoText[1] := Text104;

        if No < 1 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, ZeroText, ' ')
        else
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;
                if Hundreds > 0 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds], ' ');
                    AddToNoText(NoText, NoTextIndex, PrintExponent, HundredText, ' ');
                end;
                if Tens >= 2 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[Tens], ' ');
                    if Ones > 0 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], ' ');
                end else
                    if (Tens * 10 + Ones) > 0 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Tens * 10 + Ones], ' ');
                if PrintExponent and (Exponent > 1) then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent], ' ');
                No := No - (Hundreds * 100 + Tens * 10 + Ones) * Power(1000, Exponent - 1);
            end;

        if LanguageCode = CAEnglishLanguageCode then begin
            CentsAndCurrency := Currency.Description + ' ' + AndText + ' ' + Format(No * 100) + CentsText;
            exit(AddToNoText(NoText, NoTextIndex, PrintExponent, CentsAndCurrency, ' '));
        end;
        CentsAndCurrency := AndText + ' ' + Format(No * 100) + CentsText + ' ' + Currency.Description;
        exit(AddToNoText(NoText, NoTextIndex, PrintExponent, CentsAndCurrency, ' '));
    end;

    local procedure FormatNoTextESM(var NoText: array[2] of Text[80]; No: Decimal): Boolean
    var
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
    begin
        NoTextIndex := 1;
        NoText[1] := Text104;

        if No < 1 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, ZeroText, ' ')
        else
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;
                if Hundreds > 0 then
                    if (Hundreds = 1) and (Tens = 0) and (Ones = 0) then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, HundredText, ' ')
                    else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, HundredsText[Hundreds], ' ');
                case Tens of
                    0:
                        if (Hundreds = 0) and (Ones = 1) and (Exponent > 1) then
                            PrintExponent := true
                        else
                            if Ones > 0 then
                                AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], ' ');
                    1, 2:
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Tens * 10 + Ones], ' ');
                    else begin
                        AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[Tens], ' ');
                        if Ones <> 0 then begin
                            AddToNoText(NoText, NoTextIndex, PrintExponent, AndText, ' ');
                            AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], ' ');
                        end;
                    end;
                end;
                if PrintExponent and (Exponent > 1) then
                    if (Hundreds = 0) and (Tens = 0) and (Ones = 1) and (Exponent = 3) then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OneMillionText, ' ')
                    else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent], ' ');
                No := No - (Hundreds * 100 + Tens * 10 + Ones) * Power(1000, Exponent - 1);
            end;

        AddToNoText(NoText, NoTextIndex, PrintExponent, Currency.Description, ' ');
        exit(AddToNoText(NoText, NoTextIndex, PrintExponent, Format(No * 100) + CentsText, ' '));
    end;

    local procedure FormatNoTextFRC(var NoText: array[2] of Text[80]; No: Decimal): Boolean
    var
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
    begin
        NoTextIndex := 1;
        NoText[1] := Text104;

        if No < 1 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, ZeroText, ' ')
        else
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;

                if Hundreds = 1 then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, HundredText, ' ')
                else
                    if Hundreds > 1 then begin
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds], ' ');
                        if (Tens * 10 + Ones) = 0 then
                            AddToNoText(NoText, NoTextIndex, PrintExponent, HundredText + 's', ' ')
                        else
                            AddToNoText(NoText, NoTextIndex, PrintExponent, HundredText, ' ');
                    end;

                FormatTensFRC(NoText, NoTextIndex, PrintExponent, Exponent, Hundreds, Tens, Ones);

                if PrintExponent and (Exponent > 1) then
                    if ((Hundreds * 100 + Tens * 10 + Ones) > 1) and (Exponent <> 2) then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent] + 's', ' ')
                    else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent], ' ');

                No := No - (Hundreds * 100 + Tens * 10 + Ones) * Power(1000, Exponent - 1);
            end;

        AddToNoText(NoText, NoTextIndex, PrintExponent, Currency.Description, ' ');
        AddToNoText(NoText, NoTextIndex, PrintExponent, AndText, ' ');
        exit(AddToNoText(NoText, NoTextIndex, PrintExponent, Format(No * 100, 2) + CentsText, ' '));
    end;

    local procedure FormatTensFRC(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; var PrintExponent: Boolean; Exponent: Integer; Hundreds: Integer; Tens: Integer; Ones: Integer)
    begin
        case Tens of
            9:
                if Ones = 0 then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[9] + 's', ' ')
                else begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[8], ' ');
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones + 10], '-');
                end;
            8:
                if Ones = 0 then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[8] + 's', ' ')
                else begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[8], ' ');
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], '-');
                end;
            7:
                begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[6], ' ');
                    if Ones = 1 then begin
                        AddToNoText(NoText, NoTextIndex, PrintExponent, AndText, ' ');
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones + 10], ' ');
                    end else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones + 10], '-');
                end;
            2:
                begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[2], ' ');
                    if Ones > 0 then
                        if Ones = 1 then begin
                            AddToNoText(NoText, NoTextIndex, PrintExponent, AndText, ' ');
                            AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], ' ');
                        end else
                            AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], '-');
                end;
            1:
                AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Tens * 10 + Ones], ' ');
            0:
                if Ones > 0 then
                    if (Ones = 1) and (Hundreds < 1) and (Exponent = 2) then
                        PrintExponent := true
                    else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], ' ');
            else begin
                AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[Tens], ' ');
                if Ones > 0 then
                    if Ones = 1 then begin
                        AddToNoText(NoText, NoTextIndex, PrintExponent, AndText, ' ');
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], ' ');
                    end else
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones], '-');
            end;
        end;
    end;

    procedure MakeTestData()
    var
        i: Integer;
        j: Integer;
    begin
        TestAmount[1] := 293.38;
        TestAmount[2] := 80;
        TestAmount[3] := 100;
        TestAmount[4] := 99.45;
        TestAmount[5] := 1266;
        TestAmount[6] := 1399121.38;
        TestAmount[7] := 185.38;
        TestAmount[8] := 680.33;
        TestAmount[9] := 80.99;
        TestAmount[10] := 200.66;
        TestAmount[11] := 238.27;
        TestAmount[12] := 80765.56;
        TestAmount[13] := 1000.78;
        TestAmount[14] := 2980.32;
        TestAmount[15] := 1301476.89;
        TestAmount[16] := 2000000.38;
        TestAmount[17] := 345497.88;
        TestAmount[18] := 1000065;
        TestAmount[19] := 1500300999.38;
        TestAmount[20] := 3000000000.0;
        TestAmount[21] := 1001.99;
        TestAmount[22] := 88;
        TestAmount[23] := 121;
        TestAmount[24] := 331;
        TestAmount[25] := 3341;
        TestAmount[26] := 1051;
        TestAmount[27] := 1000061;
        TestAmount[28] := 81;
        TestAmount[29] := 11;
        TestAmount[30] := 71;
        TestAmount[31] := 91;
        TestAmount[32] := 0;
        TestAmount[33] := 1;
        TestAmount[34] := 0.99;
        TestAmount[35] := 1.23;
        TestAmount[36] := 12.34;
        TestAmount[37] := 123.45;
        TestAmount[38] := 1234.56;
        TestAmount[39] := 12345.67;
        TestAmount[40] := 123456.78;
        TestAmount[41] := 1234567.89;
        TestAmount[42] := 12345678.9;
        TestAmount[43] := 123456789.01;
        TestAmount[44] := 1234567890.12;
        TestAmount[45] := 987654321098.76;
        TestAmount[46] := 9999999999.0;
        TestAmount[47] := 1000;
        TestNumAmounts := 47;

        TestNumDates := 0;
        for i := 0 to 3 do
            for j := 0 to 3 do begin
                TestNumDates := TestNumDates + 1;
                TestDateFormat[TestNumDates] := i;
                TestDateSeparator[TestNumDates] := j;
            end;
    end;

    procedure SetCheckPrintParams(NewDateFormat: Option " ","MM DD YYYY","DD MM YYYY","YYYY MM DD"; NewDateSeparator: Option " ","-",".","/"; NewCountryCode: Code[10]; NewCheckLanguage: Option "E English","F French","S Spanish"; CheckToAddr: Text[100]; var CheckDateFormat: Option; var DateSeparator: Option; var CheckLanguage: Integer; var CheckStyle: Option ,US,CA)
    var
        WindowsLanguage: Record "Windows Language";
        CompanyInformation: Record "Company Information";
    begin
        CheckDateFormat := NewDateFormat;
        DateSeparator := NewDateSeparator;
        case NewCheckLanguage of
            NewCheckLanguage::"E English":
                if NewCountryCode = 'CA' then
                    CheckLanguage := 4105
                else
                    CheckLanguage := 1033;
            NewCheckLanguage::"F French":
                CheckLanguage := 3084;
            NewCheckLanguage::"S Spanish":
                CheckLanguage := 2058;
            else
                CheckLanguage := 1033;
        end;
        CompanyInformation.Get();
        case CompanyInformation.GetCountryRegionCode(NewCountryCode) of
            'US', 'MX':
                CheckStyle := CheckStyle::US;
            'CA':
                CheckStyle := CheckStyle::CA;
            else
                CheckStyle := CheckStyle::US;
        end;
        if CheckLanguage <> WindowsLanguage."Language ID" then
            WindowsLanguage.Get(CheckLanguage);
        if not WindowsLanguage."Globally Enabled" then
            if CheckLanguage = 4105 then
                CheckLanguage := 1033
            else
                Error(USTextErr, WindowsLanguage.Name, CheckToAddr);
    end;
}

