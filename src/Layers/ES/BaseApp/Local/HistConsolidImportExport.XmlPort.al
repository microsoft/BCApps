// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Finance.Currency;

xmlport 10700 "Hist. Consolid. Import/Export"
{
    Caption = 'Hist. Consolid. Import/Export';
    FormatEvaluate = Xml;

    schema
    {
        textelement(subFinReport)
        {
            MaxOccurs = Once;
            MinOccurs = Once;
            textattribute(product)
            {
            }
            textattribute(productVersion)
            {
            }
            textattribute(formatVersion)
            {

                trigger OnAfterAssignVariable()
                begin
                    // add code here to test format Version against CurrentFormatVersion.
                    // if different only behind the decimal point, than ok.
                    // if different before the decimal, then give error message.
                end;
            }
            textattribute(subCompanyName)
            {
            }
            textattribute(currencyLCY)
            {
                Occurrence = Optional;
            }
            textattribute(currencyACY)
            {
                Occurrence = Optional;
            }
            textattribute(currencyPCY)
            {
                Occurrence = Optional;
            }
            textattribute(checkSum)
            {
            }
            textattribute(startingDate)
            {
                Occurrence = Optional;
            }
            textattribute(endingDate)
            {
            }
            textattribute(reportingDate)
            {
            }
            textattribute(reportingUserID)
            {
            }
            textelement(exchRateTable)
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                tableelement("Currency Exchange Rate"; "Currency Exchange Rate")
                {
                    MinOccurs = Zero;
                    XmlName = 'exchRate';
                    SourceTableView = sorting("Currency Code", "Starting Date");
                    UseTemporary = true;
                    fieldattribute(currencyCode; "Currency Exchange Rate"."Currency Code")
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(relCurrencyCode; "Currency Exchange Rate"."Relational Currency Code")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(startingDate; "Currency Exchange Rate"."Starting Date")
                    {
                    }
                    fieldattribute(exchRateAmount; "Currency Exchange Rate"."Exchange Rate Amount")
                    {
                    }
                    fieldattribute(relExchRateAmount; "Currency Exchange Rate"."Relational Exch. Rate Amount")
                    {
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        CurrentProduct: Label 'Microsoft Dynamics NAV';
        CurrentProductVersion: Label '4.00';
        CurrentFormatVersion: Label '1.00';

    [Scope('OnPrem')]
    procedure SetGlobals(NewCompanyName: Text[30]; NewCurrencyLCY: Code[10]; NewCurrencyACY: Code[10]; NewCurrencyPCY: Code[10]; NewCheckSum: Decimal; NewStartingDate: Date; NewEndingDate: Date)
    begin
        product := CurrentProduct;
        productVersion := CurrentProductVersion;
        formatVersion := CurrentFormatVersion;
        subCompanyName := NewCompanyName;
        currencyLCY := NewCurrencyLCY;
        currencyACY := NewCurrencyACY;
        currencyPCY := NewCurrencyPCY;
        checkSum := DecimalToXMLText(NewCheckSum);
        startingDate := DateToXMLText(NewStartingDate);
        endingDate := DateToXMLText(NewEndingDate);
        reportingDate := DateToXMLText(Today);
        reportingUserID := UserId;
    end;

    [Scope('OnPrem')]
    procedure GetGlobals(var ImpProductVersion: Code[10]; var ImpFormatVersion: Code[10]; var ImpCompanyName: Text[30]; var ImpCurrencyLCY: Code[10]; var ImpCurrencyACY: Code[10]; var ImpCurrencyPCY: Code[10]; var ImpCheckSum: Decimal; var ImpStartingDate: Date; var ImpEndingDate: Date)
    begin
        ImpProductVersion := productVersion;
        ImpFormatVersion := formatVersion;
        ImpCompanyName := subCompanyName;
        ImpCurrencyLCY := currencyLCY;
        ImpCurrencyACY := currencyACY;
        ImpCurrencyPCY := currencyPCY;
        ImpCheckSum := XMLTextToDecimal(checkSum);
        ImpStartingDate := XMLTextToDate(startingDate);
        ImpEndingDate := XMLTextToDate(endingDate);
    end;


    [Scope('OnPrem')]
    procedure SetExchRate(var TempExchRate: Record "Currency Exchange Rate")
    begin
        "Currency Exchange Rate".Reset();
        "Currency Exchange Rate".DeleteAll();
        if TempExchRate.Find('-') then
            repeat
                "Currency Exchange Rate" := TempExchRate;
                "Currency Exchange Rate".Insert();
            until TempExchRate.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetExchRate(var TempExchRate: Record "Currency Exchange Rate")
    begin
        TempExchRate.Reset();
        TempExchRate.DeleteAll();
        "Currency Exchange Rate".Reset();
        if "Currency Exchange Rate".Find('-') then
            repeat
                TempExchRate := "Currency Exchange Rate";
                TempExchRate.Insert();
            until "Currency Exchange Rate".Next() = 0;
    end;

    local procedure DateToXMLText(Date: Date) XMLText: Text[30]
    begin
        XMLText := Format(Date, 10, '<Year4>-<Month,2>-<Day,2>');
    end;

    local procedure XMLTextToDate(XMLText: Text[30]) Date: Date
    var
        Month: Integer;
        Day: Integer;
        Year: Integer;
    begin
        Evaluate(Year, CopyStr(XMLText, 1, 4));
        Evaluate(Month, CopyStr(XMLText, 6, 2));
        Evaluate(Day, CopyStr(XMLText, 9, 2));
        Date := DMY2Date(Day, Month, Year);
    end;

    local procedure DecimalToXMLText(Amount: Decimal) XMLText: Text[30]
    var
        BeforePoint: Decimal;
        AfterPoint: Decimal;
        Places: Integer;
        Minus: Boolean;
    begin
        Minus := (Amount < 0);
        if Minus then
            Amount := -Amount;
        BeforePoint := Round(Amount, 1, '<');
        AfterPoint := Amount - BeforePoint;
        Places := 0;
        while Round(AfterPoint, 1) <> AfterPoint do begin
            AfterPoint := AfterPoint * 10;
            Places := Places + 1;
        end;
        XMLText :=
          Format(BeforePoint, 0, 1) + '.' + ConvertStr(Format(AfterPoint, Places, 1), ' ', '0');
        if Minus then
            XMLText := '-' + XMLText;
    end;

    local procedure XMLTextToDecimal(XMLText: Text[30]) Amount: Decimal
    var
        BeforePoint: Decimal;
        AfterPoint: Decimal;
        BeforeText: Text[30];
        AfterText: Text[30];
        Minus: Boolean;
        Places: Integer;
        Point: Integer;
    begin
        if StrLen(XMLText) = 0 then
            exit(0);
        Minus := (XMLText[1] = '-');
        if Minus then
            XMLText := DelStr(XMLText, 1, 1);
        Point := StrLen(XMLText);
        AfterText := '';
        while (XMLText[Point] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) and
              (Point > 1)
        do begin
            Places := Places + 1;
            AfterText := ' ' + AfterText;
            AfterText[1] := XMLText[Point];
            Point := Point - 1;
        end;
        BeforeText := DelChr(CopyStr(XMLText, 1, Point), '=', '.,');
        Evaluate(BeforePoint, BeforeText);
        Evaluate(AfterPoint, AfterText);
        while Places > 0 do begin
            AfterPoint := AfterPoint / 10;
            Places := Places - 1;
        end;
        Amount := BeforePoint + AfterPoint;
        if Minus then
            Amount := -Amount;
    end;
}
