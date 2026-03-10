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

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;

        if not HasDataToMigrate() then
            exit(true);

        if BC14CurrencyExchangeRate.FindSet() then
            repeat
                if not TryMigrateCurrencyExchangeRate(BC14CurrencyExchangeRate) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Currency Exchange Rate", 'BC14 Currency Exchange Rate', BC14CurrencyExchangeRate."Currency Code" + '-' + Format(BC14CurrencyExchangeRate."Starting Date"), Database::"Currency Exchange Rate", GetLastErrorText(), BC14CurrencyExchangeRate.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14CurrencyExchangeRate.Next() = 0;

        exit(Success);
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
        // Fix Exchange Rate Amount: 0 = Currency, 1 = Relational Currency, 2 = Both
        case BC14CurrencyExchangeRate."Fix Exchange Rate Amount" of
            0:
                CurrencyExchangeRate."Fix Exchange Rate Amount" := CurrencyExchangeRate."Fix Exchange Rate Amount"::Currency;
            1:
                CurrencyExchangeRate."Fix Exchange Rate Amount" := CurrencyExchangeRate."Fix Exchange Rate Amount"::"Relational Currency";
            2:
                CurrencyExchangeRate."Fix Exchange Rate Amount" := CurrencyExchangeRate."Fix Exchange Rate Amount"::Both;
        end;

        // Allow extensions to map custom fields
        OnTransferCurrExchRateCustomFields(BC14CurrencyExchangeRate, CurrencyExchangeRate);
    end;

    /// <summary>
    /// Integration event raised during currency exchange rate migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferCurrExchRateCustomFields(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;
}
