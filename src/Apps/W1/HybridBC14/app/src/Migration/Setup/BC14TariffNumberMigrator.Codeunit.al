// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Intrastat;

codeunit 46917 "BC14 Tariff Number Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Tariff Number";

    trigger OnRun()
    begin
        MigrateTariffNumber(Rec);
    end;

    var
        MigratorNameLbl: Label 'Tariff Number Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Tariff Number", Database::"BC14 Tariff Number");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14TariffNumber: Record "BC14 Tariff Number";
    begin
        exit(not BC14TariffNumber.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14TariffNumber: Record "BC14 Tariff Number";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14TariffNumber;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Tariff Number Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14TariffNumber: Record "BC14 Tariff Number";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Tariff Number", BC14TariffNumber.Count()));
    end;

    internal procedure MigrateTariffNumber(BC14TariffNumber: Record "BC14 Tariff Number")
    var
        TariffNumber: Record "Tariff Number";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateTariffNumber(BC14TariffNumber, IsMigrated);
        if IsMigrated then
            exit;

        if TariffNumber.Get(BC14TariffNumber."No.") then begin
            TransferFields(BC14TariffNumber, TariffNumber);
            TariffNumber.Modify();
        end else begin
            TariffNumber.Init();
            TransferFields(BC14TariffNumber, TariffNumber);
            TariffNumber.Insert();
        end;

        OnAfterMigrateTariffNumber(BC14TariffNumber, TariffNumber);
    end;

    local procedure TransferFields(BC14TariffNumber: Record "BC14 Tariff Number"; var TariffNumber: Record "Tariff Number")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        TariffNumber."No." := BC14TariffNumber."No.";

        // Direct-assign rather than Validate: the Intrastat Report tableextension hooks into Tariff
        // Number OnValidate / OnModify to ask the user via Confirm whether to update related items.
        // Confirm cannot run in the background task session that hosts the migration, so any Validate
        // that triggers it would error out. The values are migrated as-is.
        TariffNumber.Description := BC14TariffNumber.Description;
        TariffNumber."Supplementary Units" := BC14TariffNumber."Supplementary Units";

        OnTransferTariffNumberCustomFields(BC14TariffNumber, TariffNumber);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateTariffNumber(BC14TariffNumber: Record "BC14 Tariff Number"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateTariffNumber(BC14TariffNumber: Record "BC14 Tariff Number"; var TariffNumber: Record "Tariff Number")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferTariffNumberCustomFields(BC14TariffNumber: Record "BC14 Tariff Number"; var TariffNumber: Record "Tariff Number")
    begin
    end;
}

