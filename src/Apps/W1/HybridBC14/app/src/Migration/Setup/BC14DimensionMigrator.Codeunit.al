// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.Dimension;

codeunit 46890 "BC14 Dimension Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Dimension";

    trigger OnRun()
    begin
        MigrateDimension(Rec);
    end;

    var
        MigratorNameLbl: Label 'Dimension Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Dimension", Database::"BC14 Dimension");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14Dimension: Record "BC14 Dimension";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateDimensions(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14Dimension;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Dimension Migrator");

        OnAfterMigrateDimensions(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Dimension: Record "BC14 Dimension";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Dimension", BC14Dimension.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14Dimension: Record "BC14 Dimension";
    begin
        exit(not BC14Dimension.IsEmpty());
    end;

    internal procedure MigrateDimension(BC14Dimension: Record "BC14 Dimension")
    var
        Dimension: Record Dimension;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateDimension(BC14Dimension, IsMigrated);
        if IsMigrated then
            exit;

        if Dimension.Get(BC14Dimension.Code) then begin
            TransferFields(BC14Dimension, Dimension);
            Dimension.Modify(true);
        end else begin
            Dimension.Init();
            TransferFields(BC14Dimension, Dimension);
            Dimension.Insert(true);
        end;

        OnAfterMigrateDimension(BC14Dimension, Dimension);
    end;

    local procedure TransferFields(BC14Dimension: Record "BC14 Dimension"; var Dimension: Record Dimension)
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        Dimension.Code := BC14Dimension.Code;

        // Use Validate so any OnValidate business logic runs.
        Dimension.Validate(Name, BC14Dimension.Name);
        Dimension.Validate("Code Caption", BC14Dimension."Code Caption");
        Dimension.Validate("Filter Caption", BC14Dimension."Filter Caption");
        Dimension.Validate(Description, BC14Dimension.Description);
        Dimension.Validate(Blocked, BC14Dimension.Blocked);
        Dimension.Validate("Consolidation Code", BC14Dimension."Consolidation Code");
        Dimension.Validate("Map-to IC Dimension Code", BC14Dimension."Map-to IC Dimension Code");

        OnTransferDimensionCustomFields(BC14Dimension, Dimension);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateDimensions(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateDimensions(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateDimension(BC14Dimension: Record "BC14 Dimension"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateDimension(BC14Dimension: Record "BC14 Dimension"; var Dimension: Record Dimension)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferDimensionCustomFields(BC14Dimension: Record "BC14 Dimension"; var Dimension: Record Dimension)
    begin
    end;
}

