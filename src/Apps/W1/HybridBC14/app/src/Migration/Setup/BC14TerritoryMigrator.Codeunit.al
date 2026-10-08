// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Intrastat;

codeunit 46914 "BC14 Territory Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Territory";

    trigger OnRun()
    begin
        MigrateTerritory(Rec);
    end;

    var
        MigratorNameLbl: Label 'Territory Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Territory", Database::"BC14 Territory");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14Territory: Record "BC14 Territory";
    begin
        exit(not BC14Territory.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14Territory: Record "BC14 Territory";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14Territory;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Territory Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Territory: Record "BC14 Territory";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Territory", BC14Territory.Count()));
    end;

    internal procedure MigrateTerritory(BC14Territory: Record "BC14 Territory")
    var
        Territory: Record Territory;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateTerritory(BC14Territory, IsMigrated);
        if IsMigrated then
            exit;

        if Territory.Get(BC14Territory.Code) then begin
            TransferFields(BC14Territory, Territory);
            Territory.Modify();
        end else begin
            Territory.Init();
            TransferFields(BC14Territory, Territory);
            Territory.Insert();
        end;

        OnAfterMigrateTerritory(BC14Territory, Territory);
    end;

    local procedure TransferFields(BC14Territory: Record "BC14 Territory"; var Territory: Record Territory)
    begin
        Territory.Code := BC14Territory.Code;
        // Territory has no Description field on the modern table.

        OnTransferTerritoryCustomFields(BC14Territory, Territory);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateTerritory(BC14Territory: Record "BC14 Territory"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateTerritory(BC14Territory: Record "BC14 Territory"; var Territory: Record Territory)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferTerritoryCustomFields(BC14Territory: Record "BC14 Territory"; var Territory: Record Territory)
    begin
    end;
}

