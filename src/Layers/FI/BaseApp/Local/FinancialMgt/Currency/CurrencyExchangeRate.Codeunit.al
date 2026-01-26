// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

codeunit 32000001 "Currency Exchange Rate"
{

    trigger OnRun()
    var
        FileName: Text;
    begin
        OnBeforeFileImport(FileName);
        if FileName = '' then begin
            FileName := FileMgt.ServerTempFileName('');
            if not Upload(OpenFileTxt, '', '', '', FileName) then
                exit;
        end;

        CurrencyFile.Open(FileName);
        CurrencyFile.TextMode(true);
        UusienlukuOK := false;
        Counter2 := 0;
        Counter := Round(CurrencyFile.Len / 152, 1);
        if Counter < 1 then begin
            CurrencyFile.Close();
            exit;
        end;

        GLSetup.Get();

        repeat
            CurrencyFile.Read(Tietuerivi);
            Tietuetunnus := CopyStr(Tietuerivi, 5, 3);

            if Tietuetunnus = '001' then begin
                Valuuttakoodi := CopyStr(Tietuerivi, 26, 3);
                TiedostonValuutta := CopyStr(Tietuerivi, 29, 3);

                if TiedostonValuutta <> 'EUR' then begin
                    CurrencyFile.Close();
                    Error(Text1090000);
                end;

                Evaluate(Aloitusv, CopyStr(Tietuerivi, 8, 4));
                Evaluate(Aloituskk, CopyStr(Tietuerivi, 12, 2));
                Evaluate(Aloituspvm, CopyStr(Tietuerivi, 14, 2));
                Evaluate(Vaihtokurssisumma, CopyStr(Tietuerivi, 32, 13));
                Evaluate(EuroValuutta, CopyStr(Tietuerivi, 99, 1));

                Vaihtokurssisumma := Vaihtokurssisumma / 10000000;
                Vaihtokurssisumma := Round(Vaihtokurssisumma, 0.0000001);
                StartingDate := DMY2Date(Aloituspvm, Aloituskk, Aloitusv);

                Currency.SetFilter(Code, Valuuttakoodi);
                CurrencyExchRate.SetFilter("Currency Code", Valuuttakoodi);
                CurrencyExchRate.SetRange("Starting Date", StartingDate);

                if CurrencyExchRate.FindFirst() = false then
                    if Currency.FindFirst() then begin
                        UusienlukuOK := true;
                        CurrencyExchRate.Validate("Currency Code", Valuuttakoodi);
                        CurrencyExchRate.Validate("Starting Date", StartingDate);
                        case EuroValuutta of
                            1:
                                begin
                                    CurrencyExchRate.Validate("Fix Exchange Rate Amount", 2);
                                    Currency.Validate("EMU Currency", true);
                                    if Valuuttakoodi <> 'EUR' then
                                        CurrencyExchRate.Validate("Relational Currency Code", 'EUR');
                                    CurrencyExchRate.Validate("Exchange Rate Amount", Vaihtokurssisumma);
                                    CurrencyExchRate.Validate("Adjustment Exch. Rate Amount", Vaihtokurssisumma);
                                    CurrencyExchRate.Validate("Relational Exch. Rate Amount", 1);
                                    CurrencyExchRate.Validate("Relational Adjmt Exch Rate Amt", 1);
                                    CurrencyExchRate."Fix Exchange Rate Amount" := CurrencyExchRate."Fix Exchange Rate Amount"::Both;
                                end;
                            0:
                                begin
                                    CurrencyExchRate.Validate("Fix Exchange Rate Amount", 0);
                                    CurrencyExchRate.Validate("Relational Currency Code", '');
                                    CurrencyExchRate.Validate("Exchange Rate Amount", Vaihtokurssisumma);
                                    CurrencyExchRate.Validate("Adjustment Exch. Rate Amount", Vaihtokurssisumma);
                                    CurrencyExchRate.Validate("Relational Exch. Rate Amount", 1);
                                    CurrencyExchRate.Validate("Relational Adjmt Exch Rate Amt", 1);
                                    CurrencyExchRate."Fix Exchange Rate Amount" := CurrencyExchRate."Fix Exchange Rate Amount"::"Relational Currency";
                                end;
                        end;
                        Currency.Modify();
                        CurrencyExchRate.Insert();
                    end;
            end;
            Counter2 := Counter2 + 1;
        until Counter2 >= Counter;

        if UusienlukuOK then
            Message(Text1090001)
        else
            Message(Text1090002);

        CurrencyFile.Close();
        BackUp := '.000';
        while FILE.Exists(FileName + BackUp) do
            BackUp := IncStr(BackUp);
        FILE.Rename(FileName, FileName + BackUp);
    end;

    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        FileMgt: Codeunit "File Management";
        CurrencyFile: File;
        Tietuerivi: Text[155];
        Tietuetunnus: Text[3];
        Counter: Integer;
        Counter2: Integer;
        Valuuttakoodi: Code[10];
        StartingDate: Date;
        Vaihtokurssisumma: Decimal;
        Aloituspvm: Integer;
        Aloituskk: Integer;
        Aloitusv: Integer;
        UusienlukuOK: Boolean;
        EuroValuutta: Integer;
        TiedostonValuutta: Code[10];
        BackUp: Text[30];
        Text1090000: Label 'File does not contain Exchange rates in LCY Currency';
        Text1090001: Label 'New Exchange Rates updated ';
        Text1090002: Label 'No updated currencies';
        OpenFileTxt: Label 'Open currency exchange rate file';

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeFileImport(var FileName: Text)
    begin
    end;
}

