// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

xmlport 1 "Consolidation Import/Export"
{
    Caption = 'Consolidation Import/Export';
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
            textattribute(startingDateIsClosing)
            {
                Occurrence = Optional;
            }
            textattribute(endingDate)
            {
            }
            textattribute(endingDateIsClosing)
            {
                Occurrence = Optional;
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
            textelement(glAccountTable)
            {
                MaxOccurs = Once;
                MinOccurs = Once;
                tableelement("G/L Account"; "G/L Account")
                {
                    XmlName = 'glAccount';
                    SourceTableView = sorting("No.");
                    UseTemporary = true;
                    fieldattribute(no; "G/L Account"."No.")
                    {
                    }
                    fieldattribute(accountDebit; "G/L Account"."Consol. Debit Acc.")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(accountCredit; "G/L Account"."Consol. Credit Acc.")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(translationMethod; "G/L Account"."Consol. Translation Method")
                    {
                    }
                    tableelement("G/L Entry"; "G/L Entry")
                    {
                        LinkFields = "G/L Account No." = field("No.");
                        LinkTable = "G/L Account";
                        MinOccurs = Zero;
                        XmlName = 'glEntry';
                        SourceTableView = sorting("G/L Account No.", "Posting Date");
                        UseTemporary = true;
                        fieldattribute(postingDate; "G/L Entry"."Posting Date")
                        {
                        }
                        textattribute(isClosingEntry)
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(amountDebit; "G/L Entry"."Debit Amount")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(amountCredit; "G/L Entry"."Credit Amount")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(arcAmountDebit; "G/L Entry"."Add.-Currency Debit Amount")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(arcAmountCredit; "G/L Entry"."Add.-Currency Credit Amount")
                        {
                            Occurrence = Optional;
                        }
                        tableelement("Dimension Buffer"; "Dimension Buffer")
                        {
                            LinkFields = "Entry No." = field("Entry No.");
                            LinkTable = "G/L Entry";
                            MinOccurs = Zero;
                            XmlName = 'dimension';
                            SourceTableView = where("Table ID" = const(17));
                            UseTemporary = true;
                            fieldattribute(code; "Dimension Buffer"."Dimension Code")
                            {
                            }
                            fieldattribute(value; "Dimension Buffer"."Dimension Value Code")
                            {
                            }

                            trigger OnBeforeInsertRecord()
                            begin
                                "Dimension Buffer"."Table ID" := DATABASE::"G/L Entry";
                                "Dimension Buffer"."Entry No." := "G/L Entry"."Entry No.";
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "G/L Entry"."Posting Date" = NormalDate("G/L Entry"."Posting Date") then
                                isClosingEntry := ''
                            else
                                isClosingEntry := '1';
                        end;

                        trigger OnAfterInsertRecord()
                        begin
                            NextGLEntryNo := NextGLEntryNo + 1;
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            "G/L Entry"."Entry No." := NextGLEntryNo;
                            "G/L Entry"."G/L Account No." := "G/L Account"."No.";
                            if isClosingEntry = '1' then
                                "G/L Entry"."Posting Date" := ClosingDate("G/L Entry"."Posting Date");
                        end;
                    }
                }
            }

            trigger OnAfterAssignVariable()
            begin
                NextGLEntryNo := 1;
            end;
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
#pragma warning disable AA0074
        CurrentProduct: Label 'Microsoft Dynamics NAV';
        CurrentProductVersion: Label '4.00';
        CurrentFormatVersion: Label '1.00';
#pragma warning restore AA0074
        NextGLEntryNo: Integer;

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

        if NewStartingDate = NormalDate(NewStartingDate) then
            startingDateIsClosing := ''
        else
            startingDateIsClosing := '1';

        if NewEndingDate = NormalDate(NewEndingDate) then
            endingDateIsClosing := ''
        else
            endingDateIsClosing := '1';
    end;

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

        if startingDateIsClosing = '1' then
            ImpStartingDate := ClosingDate(ImpStartingDate);

        if endingDateIsClosing = '1' then
            ImpEndingDate := ClosingDate(ImpEndingDate);
    end;

    procedure SetGLAccount(var TempGLAccount: Record "G/L Account")
    begin
        "G/L Account".Reset();
        "G/L Account".DeleteAll();
        if TempGLAccount.Find('-') then
            repeat
                "G/L Account" := TempGLAccount;
                "G/L Account".Insert();
            until TempGLAccount.Next() = 0;
    end;

    procedure GetGLAccount(var TempGLAccount: Record "G/L Account")
    begin
        TempGLAccount.Reset();
        TempGLAccount.DeleteAll();
        "G/L Account".Reset();
        if "G/L Account".Find('-') then
            repeat
                TempGLAccount := "G/L Account";
                TempGLAccount.Insert();
            until "G/L Account".Next() = 0;
    end;

    procedure SetGLEntry(var TempGLEntry: Record "G/L Entry")
    begin
        "G/L Entry".Reset();
        "G/L Entry".DeleteAll();
        if TempGLEntry.Find('-') then
            repeat
                "G/L Entry" := TempGLEntry;
                "G/L Entry".Insert();
            until TempGLEntry.Next() = 0;
    end;

    procedure GetGLEntry(var TempGLEntry: Record "G/L Entry")
    begin
        TempGLEntry.Reset();
        TempGLEntry.DeleteAll();
        "G/L Entry".Reset();
        if "G/L Entry".Find('-') then
            repeat
                TempGLEntry := "G/L Entry";
                TempGLEntry.Insert();
            until "G/L Entry".Next() = 0;
    end;

    procedure SetEntryDim(var TempDimBuf: Record "Dimension Buffer" temporary)
    begin
        "Dimension Buffer".Reset();
        "Dimension Buffer".DeleteAll();
        if TempDimBuf.Find('-') then
            repeat
                "Dimension Buffer" := TempDimBuf;
                "Dimension Buffer".Insert();
            until TempDimBuf.Next() = 0;
    end;

    procedure GetEntryDim(var TempDimBuf: Record "Dimension Buffer" temporary)
    begin
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        "Dimension Buffer".Reset();
        if "Dimension Buffer".Find('-') then
            repeat
                TempDimBuf := "Dimension Buffer";
                TempDimBuf.Insert();
            until "Dimension Buffer".Next() = 0;
    end;

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

