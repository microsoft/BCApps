// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.Currency;

codeunit 46893 "BC14 Currency Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Currency";

    trigger OnRun()
    begin
        MigrateCurrency(Rec);
    end;

    var
        MigratorNameLbl: Label 'Currency Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Currency", Database::"BC14 Currency");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14Currency: Record "BC14 Currency";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCurrencies(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14Currency;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Currency Migrator");

        OnAfterMigrateCurrencies(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Currency: Record "BC14 Currency";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Currency", BC14Currency.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14Currency: Record "BC14 Currency";
    begin
        exit(not BC14Currency.IsEmpty());
    end;

    internal procedure MigrateCurrency(BC14Currency: Record "BC14 Currency")
    var
        Currency: Record Currency;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCurrency(BC14Currency, IsMigrated);
        if IsMigrated then
            exit;

        if Currency.Get(BC14Currency.Code) then begin
            TransferFields(BC14Currency, Currency);
            Currency.Modify(true);
        end else begin
            Currency.Init();
            TransferFields(BC14Currency, Currency);
            Currency.Insert(true);
        end;

        OnAfterMigrateCurrency(BC14Currency, Currency);
    end;

    local procedure TransferFields(BC14Currency: Record "BC14 Currency"; var Currency: Record Currency)
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        Currency.Code := BC14Currency.Code;

        // Use Validate so any OnValidate business logic runs.
        Currency.Validate(Description, BC14Currency.Description);
        // G/L Account FK fields: direct assignment. Currency runs in the Setup phase, before
        // G/L Account is migrated in the Master phase, so Validate's TableRelation check would
        // always fail on a freshly-created target company. Accounts are verified lazily when
        // actually posted against. See BC14SetupMigrator / BC14MasterMigrator enums for phase order.
        Currency."Unrealized Gains Acc." := BC14Currency."Unrealized Gains Acc.";
        Currency."Realized Gains Acc." := BC14Currency."Realized Gains Acc.";
        Currency."Unrealized Losses Acc." := BC14Currency."Unrealized Losses Acc.";
        Currency."Realized Losses Acc." := BC14Currency."Realized Losses Acc.";
        Currency.Validate("Invoice Rounding Precision", BC14Currency."Invoice Rounding Precision");
        case BC14Currency."Invoice Rounding Type" of
            0:
                Currency.Validate("Invoice Rounding Type", Currency."Invoice Rounding Type"::Nearest);
            1:
                Currency.Validate("Invoice Rounding Type", Currency."Invoice Rounding Type"::Up);
            2:
                Currency.Validate("Invoice Rounding Type", Currency."Invoice Rounding Type"::Down);
        end;
        Currency.Validate("Amount Rounding Precision", BC14Currency."Amount Rounding Precision");
        Currency.Validate("Unit-Amount Rounding Precision", BC14Currency."Unit-Amount Rounding Precision");
        Currency.Validate("Amount Decimal Places", BC14Currency."Amount Decimal Places");
        Currency.Validate("Unit-Amount Decimal Places", BC14Currency."Unit-Amount Decimal Places");
        Currency.Validate("Appln. Rounding Precision", BC14Currency."Appln. Rounding Precision");
        Currency.Validate("EMU Currency", BC14Currency."EMU Currency");
        // G/L Account FK fields: direct assignment (see comment above).
        Currency."Residual Gains Account" := BC14Currency."Residual Gains Account";
        Currency."Residual Losses Account" := BC14Currency."Residual Losses Account";
        Currency."Conv. LCY Rndg. Debit Acc." := BC14Currency."Conv. LCY Rndg. Debit Acc.";
        Currency."Conv. LCY Rndg. Credit Acc." := BC14Currency."Conv. LCY Rndg. Credit Acc.";
        Currency.Validate("Max. VAT Difference Allowed", BC14Currency."Max. VAT Difference Allowed");
        case BC14Currency."VAT Rounding Type" of
            0:
                Currency.Validate("VAT Rounding Type", Currency."VAT Rounding Type"::Nearest);
            1:
                Currency.Validate("VAT Rounding Type", Currency."VAT Rounding Type"::Up);
            2:
                Currency.Validate("VAT Rounding Type", Currency."VAT Rounding Type"::Down);
        end;
        Currency.Validate(Symbol, BC14Currency.Symbol);
        Currency.Validate("ISO Code", BC14Currency."ISO Code");
        Currency.Validate("ISO Numeric Code", BC14Currency."ISO Numeric Code");

        OnTransferCurrencyCustomFields(BC14Currency, Currency);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCurrencies(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCurrencies(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCurrency(BC14Currency: Record "BC14 Currency"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCurrency(BC14Currency: Record "BC14 Currency"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCurrencyCustomFields(BC14Currency: Record "BC14 Currency"; var Currency: Record Currency)
    begin
    end;
}

