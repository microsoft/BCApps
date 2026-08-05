// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

codeunit 13415 "Currency Exch. Rate Import"
{
    InherentEntitlements = X;
    InherentPermissions = X;

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
        NewExchangeRatesImported := false;
        ProcessedRecordCount := 0;
        // Each data record is 151 characters followed by a line-ending character.
        TotalRecordCount := Round(CurrencyFile.Len / 152, 1);
        if TotalRecordCount < 1 then begin
            CurrencyFile.Close();
            exit;
        end;

        GLSetup.Get();

        repeat
            CurrencyFile.Read(RecordLine);
            RecordIdentifier := CopyStr(RecordLine, 5, 3);

            if RecordIdentifier = '001' then begin
                CurrencyCode := CopyStr(RecordLine, 26, 3);
                FileCurrencyCode := CopyStr(RecordLine, 29, 3);

                if FileCurrencyCode <> 'EUR' then begin
                    CurrencyFile.Close();
                    Error(InvalidFileCurrencyErr);
                end;

                Evaluate(StartingYear, CopyStr(RecordLine, 8, 4));
                Evaluate(StartingMonth, CopyStr(RecordLine, 12, 2));
                Evaluate(StartingDay, CopyStr(RecordLine, 14, 2));
                Evaluate(ExchangeRateAmount, CopyStr(RecordLine, 32, 13));
                Evaluate(EuroCurrencyIndicator, CopyStr(RecordLine, 99, 1));

                ExchangeRateAmount := ExchangeRateAmount / 10000000;
                ExchangeRateAmount := Round(ExchangeRateAmount, 0.0000001);
                StartingDate := DMY2Date(StartingDay, StartingMonth, StartingYear);

                if not CurrencyExchRate.Get(CurrencyCode, StartingDate) then
                    if Currency.Get(CurrencyCode) then begin
                        NewExchangeRatesImported := true;
                        CurrencyExchRate.Validate("Currency Code", CurrencyCode);
                        CurrencyExchRate.Validate("Starting Date", StartingDate);
                        case EuroCurrencyIndicator of
                            1:
                                begin
                                    CurrencyExchRate.Validate("Fix Exchange Rate Amount", 2);
                                    Currency.Validate("EMU Currency", true);
                                    if CurrencyCode <> 'EUR' then
                                        CurrencyExchRate.Validate("Relational Currency Code", 'EUR');
                                    CurrencyExchRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
                                    CurrencyExchRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
                                    CurrencyExchRate.Validate("Relational Exch. Rate Amount", 1);
                                    CurrencyExchRate.Validate("Relational Adjmt Exch Rate Amt", 1);
                                    CurrencyExchRate."Fix Exchange Rate Amount" := CurrencyExchRate."Fix Exchange Rate Amount"::Both;
                                end;
                            0:
                                begin
                                    CurrencyExchRate.Validate("Fix Exchange Rate Amount", 0);
                                    CurrencyExchRate.Validate("Relational Currency Code", '');
                                    CurrencyExchRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
                                    CurrencyExchRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
                                    CurrencyExchRate.Validate("Relational Exch. Rate Amount", 1);
                                    CurrencyExchRate.Validate("Relational Adjmt Exch Rate Amt", 1);
                                    CurrencyExchRate."Fix Exchange Rate Amount" := CurrencyExchRate."Fix Exchange Rate Amount"::"Relational Currency";
                                end;
                        end;
                        Currency.Modify();
                        CurrencyExchRate.Insert();
                    end;
            end;
            ProcessedRecordCount += 1;
        until ProcessedRecordCount >= TotalRecordCount;

        if NewExchangeRatesImported then
            Message(NewExchangeRatesUpdatedMsg)
        else
            Message(NoCurrenciesUpdatedMsg);

        CurrencyFile.Close();
        BackupFileExtension := '.000';
        while FILE.Exists(FileName + BackupFileExtension) do
            BackupFileExtension := IncStr(BackupFileExtension);
        FILE.Rename(FileName, FileName + BackupFileExtension);
    end;

    var
        CurrencyExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        FileMgt: Codeunit "File Management";
        CurrencyFile: File;
        RecordLine: Text[155];
        RecordIdentifier: Text[3];
        TotalRecordCount: Integer;
        ProcessedRecordCount: Integer;
        CurrencyCode: Code[10];
        StartingDate: Date;
        ExchangeRateAmount: Decimal;
        StartingDay: Integer;
        StartingMonth: Integer;
        StartingYear: Integer;
        NewExchangeRatesImported: Boolean;
        EuroCurrencyIndicator: Integer;
        FileCurrencyCode: Code[10];
        BackupFileExtension: Text[30];
        InvalidFileCurrencyErr: Label 'File does not contain Exchange rates in LCY Currency';
        NewExchangeRatesUpdatedMsg: Label 'New Exchange Rates updated ';
        NoCurrenciesUpdatedMsg: Label 'No updated currencies';
        OpenFileTxt: Label 'Open currency exchange rate file';

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeFileImport(var FileName: Text)
    begin
    end;
}
