// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.UOM;

codeunit 46903 "BC14 Unit of Measure Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Unit of Measure";

    trigger OnRun()
    begin
        MigrateUnitOfMeasure(Rec);
    end;

    var
        MigratorNameLbl: Label 'Unit of Measure Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Unit of Measure", Database::"BC14 Unit of Measure");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14UnitOfMeasure: Record "BC14 Unit of Measure";
    begin
        exit(not BC14UnitOfMeasure.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14UnitOfMeasure: Record "BC14 Unit of Measure";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14UnitOfMeasure;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Unit of Measure Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14UnitOfMeasure: Record "BC14 Unit of Measure";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Unit of Measure", BC14UnitOfMeasure.Count()));
    end;

    internal procedure MigrateUnitOfMeasure(BC14UnitOfMeasure: Record "BC14 Unit of Measure")
    var
        UnitOfMeasure: Record "Unit of Measure";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateUnitOfMeasure(BC14UnitOfMeasure, IsMigrated);
        if IsMigrated then
            exit;

        if UnitOfMeasure.Get(BC14UnitOfMeasure.Code) then begin
            TransferFields(BC14UnitOfMeasure, UnitOfMeasure);
            UnitOfMeasure.Modify();
        end else begin
            UnitOfMeasure.Init();
            TransferFields(BC14UnitOfMeasure, UnitOfMeasure);
            UnitOfMeasure.Insert();
        end;

        OnAfterMigrateUnitOfMeasure(BC14UnitOfMeasure, UnitOfMeasure);
    end;

    local procedure TransferFields(BC14UnitOfMeasure: Record "BC14 Unit of Measure"; var UnitOfMeasure: Record "Unit of Measure")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        UnitOfMeasure.Code := BC14UnitOfMeasure.Code;

        // Use Validate so any OnValidate business logic runs.
        UnitOfMeasure.Validate(Description, BC14UnitOfMeasure.Description);
        UnitOfMeasure.Validate("International Standard Code", BC14UnitOfMeasure."International Standard Code");
        UnitOfMeasure.Validate(Symbol, BC14UnitOfMeasure.Symbol);

        OnTransferUnitOfMeasureCustomFields(BC14UnitOfMeasure, UnitOfMeasure);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateUnitOfMeasure(BC14UnitOfMeasure: Record "BC14 Unit of Measure"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateUnitOfMeasure(BC14UnitOfMeasure: Record "BC14 Unit of Measure"; var UnitOfMeasure: Record "Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferUnitOfMeasureCustomFields(BC14UnitOfMeasure: Record "BC14 Unit of Measure"; var UnitOfMeasure: Record "Unit of Measure")
    begin
    end;
}

