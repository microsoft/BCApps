#pragma warning disable AA0247
codeunit 12400 "Localisation Management"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Item Ledger Entry" = rimd,
                  TableData "Purch. Rcpt. Header" = rimd,
                  TableData "Purch. Rcpt. Line" = rimd,
                  TableData "Purch. Inv. Header" = rimd,
                  TableData "Purch. Inv. Line" = rimd,
                  TableData "FA Ledger Entry" = rimd,
                  TableData "Value Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Zero';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'thousand1;thousand2;thousand5,million1;million2;million5,billion1;billion2;billion5,trillion1;trillion2;trillion5';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label '*** *** ***';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName01: Label 'January';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName02: Label 'February';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName03: Label 'March';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName04: Label 'April';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName05: Label 'May';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName06: Label 'June';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName07: Label 'July';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName08: Label 'August';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName09: Label 'September';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName10: Label 'October';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName11: Label 'November';
#pragma warning restore AA0074
#pragma warning disable AA0074
        MonthName12: Label 'December';
#pragma warning restore AA0074
#pragma warning disable AA0470
        ShouldBeLaterErr: Label '%1 should be later than %2.';
#pragma warning restore AA0470
        HundredsTxt: Label 'hundred,two hundred,three  hundred,four  hundred,five  hundred,six  hundred,seven  hundred,eight  hundred,nine  hundred';
        TeensTxt: Label 'ten,eleven,twelve,thirteen,fourteen,fifteen,sixteen,seventeen,eighteen,nineteen';
        DozensTxt: Label 'twenty,thirty,forty,fifty,sixty,seventy,eighty,ninety';
        OneTxt: Label 'one1,one2,one3';
        TwoTxt: Label 'two1,two2';
        DigitsTxt: Label 'three,four,five,six,seven,eight,nine';
        YearsTxt: Label ' years ';
        MonthsTxt: Label ' months ';
        DaysTxt: Label ' days';
        NoDataTxt: Label ' no data ';
        UnitName1Txt: Label 'rubl';
        UnitName2Txt: Label 'rublya';
        UnitName5Txt: Label 'rubley';
        CentName1Txt: Label 'kopeika';
        CentName2Txt: Label 'kopeiki';
        CentName5Txt: Label 'kopeek';

    [Scope('OnPrem')]
    procedure Amount2Text(CurrencyCode: Code[10]; Amount: Decimal) AmountText: Text
    var
        Currency: Record Currency;
        DecSym: Decimal;
        DecSymFactor: Decimal;
        DecSymFormat: Text;
        DecSymsText: Text;
        DecSymFactorText: Text;
        InvoiceRoundingType: Text;
    begin
        Currency.Init();
        InvoiceRoundingType := SetRoundingPrecision(Currency);
        if CurrencyCode = '' then begin
            Currency."Unit Kind" := Currency."Unit Kind"::Male;
            Currency."Unit Name 1" := UnitName1Txt;
            Currency."Unit Name 2" := UnitName2Txt;
            Currency."Unit Name 5" := UnitName5Txt;
            Currency."Hundred Kind" := Currency."Hundred Kind"::Female;
            Currency."Hundred Name 1" := CentName1Txt;
            Currency."Hundred Name 2" := CentName2Txt;
            Currency."Hundred Name 5" := CentName5Txt;
        end else
            Currency.Get(CurrencyCode);

        if Currency."Hundred Name 1" = '' then
            DecSymFormat := '/'
        else
            DecSymFormat := '';

        DecSymFactor := Round(1 / Currency."Invoice Rounding Precision", 1, '<');
        DecSymFactorText := Format(DecSymFactor, 0, '<Integer>');
        DecSym :=
          Round(
            (Round(Amount, Currency."Invoice Rounding Precision", InvoiceRoundingType) - Round(Amount, 1, '<')) *
            DecSymFactor, 1, '<');
        DecSymsText := Format(DecSym, 0, '<Integer>');
        if StrLen(DecSymFactorText) > StrLen(DecSymsText) then
            DecSymsText := PadStr('', StrLen(DecSymFactorText) - StrLen(DecSymsText) - 1, '0') + DecSymsText;
        if DecSymFormat = '/' then
            AmountText :=
              Integer2Text(Round(Amount, Currency."Invoice Rounding Precision", InvoiceRoundingType),
                Currency."Unit Kind", '', '', '')
        else
            AmountText :=
              Integer2Text(Round(Amount, Currency."Invoice Rounding Precision", InvoiceRoundingType),
                Currency."Unit Kind", Currency."Unit Name 1", Currency."Unit Name 2", Currency."Unit Name 5");
        if DecSymFormat = '/' then begin
            if StrLen(DelChr(AmountText, '=', ' ')) > 0 then
                AmountText := AmountText + ' ';
            AmountText := AmountText +
              DecSymsText + '/' + DecSymFactorText + ' ' + Currency."Unit Name 2";
        end else begin
            if StrLen(DelChr(AmountText, '=', ' ')) > 0 then
                AmountText := AmountText + ' ';
            AmountText := AmountText + DecSymsText + ' ';
            case true of
                (DecSym = 0):
                    AmountText := AmountText + Currency."Hundred Name 5";
                (DecSym > 4) and (DecSym < 21):
                    AmountText := AmountText + Currency."Hundred Name 5";
                ((DecSym mod 10) = 1):
                    AmountText := AmountText + Currency."Hundred Name 1";
                ((DecSym mod 10) > 1) and ((DecSym mod 10) < 5):
                    AmountText := AmountText + Currency."Hundred Name 2";
                else
                    AmountText := AmountText + Currency."Hundred Name 5";
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure Amount2Text2(CurrencyCode: Code[10]; Amount: Decimal; var WholeAmountText: Text; var HundredAmount: Decimal)
    var
        Currency: Record Currency;
        DecSymFactor: Decimal;
        InvoiceRoundingType: Text;
    begin
        Currency.Init();
        InvoiceRoundingType := SetRoundingPrecision(Currency);
        if CurrencyCode = '' then
            Currency."Unit Kind" := Currency."Unit Kind"::Male
        else
            Currency.Get(CurrencyCode);

        DecSymFactor := Round(1 / Currency."Invoice Rounding Precision", 1, '<');
        HundredAmount :=
          Round(
            (Round(Amount, Currency."Invoice Rounding Precision", InvoiceRoundingType) - Round(Amount, 1, '<')) * DecSymFactor, 1, '<');
        WholeAmountText :=
          Integer2Text(Round(Amount, Currency."Invoice Rounding Precision", InvoiceRoundingType),
            Currency."Unit Kind", '', '', '');
    end;

    [Scope('OnPrem')]
    procedure Integer2Text(IntegerValue: Decimal; IntegerGender: Option Femine,Men,Neutral; IntegerNameONE: Text; IntegerNameTWO: Text; IntegerNameFIVE: Text) IntegerText: Text
    var
        DigInInteger: Code[250];
        IndDigInInteger: Integer;
        IndTriad: Integer;
        DigInTriad: array[3] of Integer;
        IndDigInTriad: Integer;
        TriadName: Text;
        Phrase: Text;
        Gender: Integer;
        HasTriad: Boolean;
    begin
        if Round(IntegerValue, 1, '<') = 0 then begin
            IntegerText := Text000;
            HasTriad := false;
        end else begin
            IntegerText := '';
            TriadName := Text001;
            DigInInteger := Format(IntegerValue, 0, '<Integer>');
            IndTriad := (StrLen(DigInInteger) + 2) div 3;
            if IndTriad > (StrLen(TriadName) - StrLen(DelChr(TriadName, '=', ',')) + 2) then begin
                IntegerText := Text002;
                exit;
            end;
            IndDigInInteger := 0;
            IndDigInTriad := (3 - (StrLen(DigInInteger) mod 3)) mod 3;
            if IndDigInTriad > 0 then begin
                DigInTriad[1] := 0;
                if IndDigInTriad > 1 then
                    DigInTriad[2] := 0;
            end;
            repeat
                repeat
                    IndDigInInteger := IndDigInInteger + 1;
                    IndDigInTriad := IndDigInTriad + 1;
                    if not Evaluate(DigInTriad[IndDigInTriad], CopyStr(DigInInteger, IndDigInInteger, 1)) then
                        DigInTriad[IndDigInTriad] := 0;
                until IndDigInTriad = 3;
                IndTriad := IndTriad - 1;
                IndDigInTriad := 0;
                case IndTriad of
                    0:
                        Gender := IntegerGender;
                    1:
                        Gender := IntegerGender::Femine;
                    else
                        Gender := IntegerGender::Men;
                end;
                if IndTriad = 0 then
                    HasTriad :=
                      Triad2Text(DigInTriad[1], DigInTriad[2], DigInTriad[3],
                        IntegerText, Gender, IntegerNameONE, IntegerNameTWO, IntegerNameFIVE)
                else begin
                    Phrase := ConvertStr(SelectStr(IndTriad, TriadName), ';', ',');
                    HasTriad :=
                      Triad2Text(DigInTriad[1], DigInTriad[2], DigInTriad[3],
                        IntegerText, Gender, SelectStr(1, Phrase), SelectStr(2, Phrase), SelectStr(3, Phrase));
                end;
            until IndDigInInteger = StrLen(DigInInteger);
        end;
        if not HasTriad then
            IntegerText := IntegerText + ' ' + IntegerNameFIVE;
    end;

    [Scope('OnPrem')]
    procedure Date2Text(DateValue: Date) DateText: Text
    begin
        if DateValue = 0D then
            exit('');
        if GlobalLanguage <> 1049 then begin
            DateText := Format(DateValue, 0, 4);
            exit;
        end;
        DateText := Format(DateValue, 0, '<Day,2> ') + Month2Text(DateValue) + Format(DateValue, 0, ' <Year4>');
    end;

    local procedure Triad2Text(C1: Integer; C2: Integer; C3: Integer; var TargetText: Text; TriadGender: Option Femine,Men,Neutral; TriadNameONE: Text; TriadNameTWO: Text; TriadNameFIVE: Text): Boolean
    var
        TriadWords: Text;
        SymbSkip: Text[1];
        NameSelect: Integer;
    begin
        if (C1 + C2 + C3) = 0 then
            exit(false);

        if C1 > 0 then begin
            TriadWords := SelectStr(C1, HundredsTxt);
            SymbSkip := ' ';
            NameSelect := 3;
        end else begin
            TriadWords := '';
            SymbSkip := '';
        end;
        if C2 = 1 then begin
            TriadWords := TriadWords + SymbSkip + SelectStr(C3 + 1, TeensTxt);
            NameSelect := 3;
        end else begin
            if C2 > 0 then begin
                TriadWords := TriadWords + SymbSkip + SelectStr(C2 - 1, DozensTxt);
                SymbSkip := ' ';
                NameSelect := 3;
            end;
            case true of
                (C3 = 1):
                    begin
                        TriadWords := TriadWords + SymbSkip + SelectStr(TriadGender + 1, OneTxt);
                        NameSelect := 1;
                    end;
                (C3 = 2):
                    begin
                        if TriadGender = TriadGender::Neutral then
                            NameSelect := TriadGender::Men
                        else
                            NameSelect := TriadGender;
                        TriadWords := TriadWords + SymbSkip + SelectStr(NameSelect + 1, TwoTxt);
                        NameSelect := 2;
                    end;
                (C3 > 0):
                    begin
                        TriadWords := TriadWords + SymbSkip + SelectStr(C3 - 2, DigitsTxt);
                        if C3 < 5 then
                            NameSelect := 2
                        else
                            NameSelect := 3;
                    end;
            end;
        end;
        if StrLen(DelChr(TargetText, '=', ' ')) = 0 then begin
            TriadWords := Triad2UpperCase(TriadWords);
            SymbSkip := '';
        end else
            SymbSkip := ' ';
        case NameSelect of
            1:
                TriadWords := TriadWords + ' ' + TriadNameONE;
            2:
                TriadWords := TriadWords + ' ' + TriadNameTWO;
            else
                TriadWords := TriadWords + ' ' + TriadNameFIVE;
        end;
        TargetText := TargetText + SymbSkip + TriadWords;
        exit(true);
    end;

    local procedure Triad2UpperCase(TriadWords: Text): Text
    var
        LowerCaseChars: Text;
        UpperCaseChars: Text;
        FirstSymb: Text[1];
        PosSymb: Integer;
    begin
        LowerCaseChars := 'abcdefghijklmnopqrstuvwxyzáíóúñÑ±ªº¿®¬½¼¡«»ÓßÔÒõÕµþÞÚýÙÛÝ¯´';
        UpperCaseChars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZÇüéâäà­åçêëèïîìÄÅÉæÆôöòûùÿÖ£øÜØ×ƒ';
        FirstSymb := CopyStr(TriadWords, 1, 1);
        PosSymb := StrPos(LowerCaseChars, FirstSymb);
        if PosSymb > 0 then
            exit(Format(UpperCaseChars[PosSymb]) + CopyStr(TriadWords, 2));

        exit(UpperCase(CopyStr(TriadWords, 1, 1)) + CopyStr(TriadWords, 2));
    end;

    [Scope('OnPrem')]
    procedure DigitalPartCode(SourceCode: Code[20]) Result: Code[20]
    var
        Index: Integer;
        Symbol: Code[1];
    begin
        Index := StrLen(SourceCode);
        while Index > 0 do begin
            Symbol := CopyStr(SourceCode, Index, 1);
            if StrPos('0123456789', Symbol) = 0 then begin
                Index := Index - 1;
                if Index > 0 then
                    SourceCode := CopyStr(SourceCode, 1, Index)
                else
                    SourceCode := '';
            end else
                Index := 0;
        end;
        Index := StrLen(SourceCode);
        Result := '';
        while Index > 0 do begin
            Symbol := CopyStr(SourceCode, Index, 1);
            if StrPos('0123456789', Symbol) = 0 then
                Index := 0
            else
                Result := Symbol + Result;
            Index := Index - 1;
        end;
        if Result = '' then
            Result := SourceCode;
    end;

    [Scope('OnPrem')]
    procedure GetPeriodDate(Date1: Date; Date2: Date; Type: Integer): Text
    var
        Delta: Integer;
        DeltaDuration: Duration;
    begin
        if (Date1 <> 0D) and (Date2 <> 0D) then begin
            DeltaDuration := Date2 - Date1;
            Delta := DeltaDuration;
            case Type of
                0:
                    exit(Format(Round(Delta / 360, 1, '<')) + GetPeriodText(1) +
                      Format(Round(Delta / 30 - Round(Delta / 360, 1, '<') * 12, 1, '<')) + GetPeriodText(2) +
                      Format(Round(Delta - Round(Delta / 360, 1, '<') * 360 - Round(Delta / 30 - Round(Delta / 360, 1, '<') * 12, 1, '<') * 30)) +
                      GetPeriodText(3));
                1:
                    exit(Format(Round(Delta / 360, 0.01, '=')) + GetPeriodText(1));
                2:
                    exit(Format(Round(Delta / 30, 1, '=')) + GetPeriodText(2));
                3:
                    exit(Format(Round(Delta, 1, '=')) + GetPeriodText(3));
            end;
        end else
            exit(NoDataTxt);
    end;

    [Scope('OnPrem')]
    procedure GetPeriodText(Type: Integer): Text
    begin
        case Type of
            1:
                exit(YearsTxt);
            2:
                exit(MonthsTxt);
            3:
                exit(DaysTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure Month2Text(Date: Date) DateText: Text
    begin
        DateText := LowerCase(Format(Date, 0, '<Month Text>'));
        if GlobalLanguage <> 1049 then
            exit;

        if StrLen(DateText) > 1 then
            case CopyStr(DateText, StrLen(DateText), 1) of
                'Ô':
                    DateText := DateText + 'á';
                'ý', '®':
                    DateText := CopyStr(DateText, 1, StrLen(DateText) - 1) + '´';
            end;
    end;

    [Scope('OnPrem')]
    procedure GetMonthName(MonthsDate: Date; Genitive: Boolean) Name: Text
    var
        MonthNo: Integer;
    begin
        if not Genitive then
            Name := Format(MonthsDate, 0, '<Month Text>')
        else begin
            MonthNo := Date2DMY(MonthsDate, 2);
            case MonthNo of
                1:
                    Name := MonthName01;
                2:
                    Name := MonthName02;
                3:
                    Name := MonthName03;
                4:
                    Name := MonthName04;
                5:
                    Name := MonthName05;
                6:
                    Name := MonthName06;
                7:
                    Name := MonthName07;
                8:
                    Name := MonthName08;
                9:
                    Name := MonthName09;
                10:
                    Name := MonthName10;
                11:
                    Name := MonthName11;
                12:
                    Name := MonthName12;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckPeriodDates(StartDate: Date; EndDate: Date): Integer
    begin
        if (StartDate <> 0D) and (EndDate <> 0D) then begin
            if StartDate > EndDate then
                Error(ShouldBeLaterErr, EndDate, StartDate);
            exit(EndDate - StartDate + 1);
        end;
    end;

    [Scope('OnPrem')]
    procedure DateMustBeLater(FieldCaption: Text; Date2: Date)
    begin
        Error(ShouldBeLaterErr, FieldCaption, Date2);
    end;

    local procedure SetRoundingPrecision(var Currency: Record Currency): Text
    begin
        Currency.InitRoundingPrecision();
        if not (Currency."Invoice Rounding Precision" in [0.1, 0.01]) then
            Currency."Invoice Rounding Precision" := 0.01;
        case Currency."Invoice Rounding Type" of
            Currency."Invoice Rounding Type"::Up:
                exit('>');
            Currency."Invoice Rounding Type"::Down:
                exit('<');
            else
                exit('=');
        end;
    end;

    [Scope('OnPrem')]
    procedure FormatDate(DateToFormat: Date): Text
    begin
        exit(Format(DateToFormat, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;
}

