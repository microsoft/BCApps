// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.Currency;

codeunit 50194 "BC14 Curr. Exch. Rate Migrator" implements "ISetupMigrator"
{
    var
        MigratorNameLbl: Label 'Currency Exchange Rate Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Currency Exchange Rate");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Currency Exchange Rate migration
    end;

    procedure IsRecordMigrated(var SourceRecordRef: RecordRef): Boolean
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
    begin
        SourceRecordRef.SetTable(BC14CurrencyExchangeRate);
        exit(CurrencyExchangeRate.Get(BC14CurrencyExchangeRate."Currency Code", BC14CurrencyExchangeRate."Starting Date"));
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
    begin
        SourceRecordRef.SetTable(BC14CurrencyExchangeRate);
        exit(TryMigrateCurrencyExchangeRate(BC14CurrencyExchangeRate));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        CurrCodeFieldRef: FieldRef;
        StartDateFieldRef: FieldRef;
    begin
        CurrCodeFieldRef := SourceRecordRef.Field(1); // Currency Code field
        StartDateFieldRef := SourceRecordRef.Field(2); // Starting Date field
        exit(Format(CurrCodeFieldRef.Value()) + '_' + Format(StartDateFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
    begin
        exit(BC14CurrencyExchangeRate.Count());
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
    begin
        exit(not BC14CurrencyExchangeRate.IsEmpty());
    end;

    [TryFunction]
    local procedure TryMigrateCurrencyExchangeRate(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyExchangeRate.Get(BC14CurrencyExchangeRate."Currency Code", BC14CurrencyExchangeRate."Starting Date") then begin
            TransferFields(BC14CurrencyExchangeRate, CurrencyExchangeRate);
            CurrencyExchangeRate.Modify(true);
        end else begin
            CurrencyExchangeRate.Init();
            TransferFields(BC14CurrencyExchangeRate, CurrencyExchangeRate);
            CurrencyExchangeRate.Insert(true);
        end;
    end;

    local procedure TransferFields(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate."Currency Code" := BC14CurrencyExchangeRate."Currency Code";
        CurrencyExchangeRate."Starting Date" := BC14CurrencyExchangeRate."Starting Date";
        CurrencyExchangeRate."Exchange Rate Amount" := BC14CurrencyExchangeRate."Exchange Rate Amount";
        CurrencyExchangeRate."Adjustment Exch. Rate Amount" := BC14CurrencyExchangeRate."Adjustment Exch. Rate Amount";
        CurrencyExchangeRate."Relational Currency Code" := BC14CurrencyExchangeRate."Relational Currency Code";
        CurrencyExchangeRate."Relational Exch. Rate Amount" := BC14CurrencyExchangeRate."Relational Exch. Rate Amount";
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := BC14CurrencyExchangeRate."Relational Adjmt Exch Rate Amt";
        case BC14CurrencyExchangeRate."Fix Exchange Rate Amount" of
            0:
                CurrencyExchangeRate."Fix Exchange Rate Amount" := CurrencyExchangeRate."Fix Exchange Rate Amount"::Currency;
            1:
                CurrencyExchangeRate."Fix Exchange Rate Amount" := CurrencyExchangeRate."Fix Exchange Rate Amount"::"Relational Currency";
            2:
                CurrencyExchangeRate."Fix Exchange Rate Amount" := CurrencyExchangeRate."Fix Exchange Rate Amount"::Both;
        end;

        OnTransferCurrExchRateCustomFields(BC14CurrencyExchangeRate, CurrencyExchangeRate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCurrExchRateCustomFields(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;
}
