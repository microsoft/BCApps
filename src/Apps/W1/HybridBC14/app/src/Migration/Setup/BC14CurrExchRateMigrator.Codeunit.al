// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.Currency;

codeunit 46894 "BC14 Curr. Exch. Rate Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Currency Exchange Rate";

    trigger OnRun()
    begin
        MigrateCurrencyExchangeRate(Rec);
    end;

    var
        MigratorNameLbl: Label 'Currency Exchange Rate Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Currency Exchange Rate", Database::"BC14 Currency Exchange Rate");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCurrencyExchangeRates(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14CurrencyExchangeRate;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Curr. Exch. Rate Migrator");

        OnAfterMigrateCurrencyExchangeRates(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Currency Exchange Rate", BC14CurrencyExchangeRate.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate";
    begin
        exit(not BC14CurrencyExchangeRate.IsEmpty());
    end;

    internal procedure MigrateCurrencyExchangeRate(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCurrencyExchangeRate(BC14CurrencyExchangeRate, IsMigrated);
        if IsMigrated then
            exit;

        if CurrencyExchangeRate.Get(BC14CurrencyExchangeRate."Currency Code", BC14CurrencyExchangeRate."Starting Date") then begin
            TransferFields(BC14CurrencyExchangeRate, CurrencyExchangeRate);
            CurrencyExchangeRate.Modify(true);
        end else begin
            CurrencyExchangeRate.Init();
            TransferFields(BC14CurrencyExchangeRate, CurrencyExchangeRate);
            CurrencyExchangeRate.Insert(true);
        end;

        OnAfterMigrateCurrencyExchangeRate(BC14CurrencyExchangeRate, CurrencyExchangeRate);
    end;

    local procedure TransferFields(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        CurrencyExchangeRate."Currency Code" := BC14CurrencyExchangeRate."Currency Code";
        CurrencyExchangeRate."Starting Date" := BC14CurrencyExchangeRate."Starting Date";

        // Use Validate so any OnValidate business logic runs.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", BC14CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", BC14CurrencyExchangeRate."Adjustment Exch. Rate Amount");
        CurrencyExchangeRate.Validate("Relational Currency Code", BC14CurrencyExchangeRate."Relational Currency Code");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", BC14CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", BC14CurrencyExchangeRate."Relational Adjmt Exch Rate Amt");
        case BC14CurrencyExchangeRate."Fix Exchange Rate Amount" of
            0:
                CurrencyExchangeRate.Validate("Fix Exchange Rate Amount", CurrencyExchangeRate."Fix Exchange Rate Amount"::Currency);
            1:
                CurrencyExchangeRate.Validate("Fix Exchange Rate Amount", CurrencyExchangeRate."Fix Exchange Rate Amount"::"Relational Currency");
            2:
                CurrencyExchangeRate.Validate("Fix Exchange Rate Amount", CurrencyExchangeRate."Fix Exchange Rate Amount"::Both);
        end;

        OnTransferCurrExchRateCustomFields(BC14CurrencyExchangeRate, CurrencyExchangeRate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCurrencyExchangeRates(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCurrencyExchangeRates(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCurrencyExchangeRate(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCurrencyExchangeRate(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCurrExchRateCustomFields(BC14CurrencyExchangeRate: Record "BC14 Currency Exchange Rate"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;
}

