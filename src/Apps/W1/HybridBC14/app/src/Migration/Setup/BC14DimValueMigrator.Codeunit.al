// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.Dimension;

codeunit 46887 "BC14 Dim. Value Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Dimension Value";

    trigger OnRun()
    begin
        MigrateDimensionValue(Rec);
    end;

    var
        MigratorNameLbl: Label 'Dimension Value Migrator';
        DimensionDoesNotExistErr: Label 'Dimension %1 does not exist. Please ensure Dimension table is migrated first.', Comment = '%1 = Dimension Code';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Dimension Value", Database::"BC14 Dimension Value");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14DimensionValue: Record "BC14 Dimension Value";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateDimensionValues(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14DimensionValue;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Dim. Value Migrator");

        OnAfterMigrateDimensionValues(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14DimensionValue: Record "BC14 Dimension Value";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Dimension Value", BC14DimensionValue.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14DimensionValue: Record "BC14 Dimension Value";
    begin
        exit(not BC14DimensionValue.IsEmpty());
    end;

    internal procedure MigrateDimensionValue(BC14DimensionValue: Record "BC14 Dimension Value")
    var
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateDimensionValue(BC14DimensionValue, IsMigrated);
        if IsMigrated then
            exit;

        if not Dimension.Get(BC14DimensionValue."Dimension Code") then
            Error(DimensionDoesNotExistErr, BC14DimensionValue."Dimension Code");

        if DimensionValue.Get(BC14DimensionValue."Dimension Code", BC14DimensionValue.Code) then begin
            TransferFields(BC14DimensionValue, DimensionValue);
            DimensionValue.Modify(true);
        end else begin
            DimensionValue.Init();
            DimensionValue."Dimension Code" := BC14DimensionValue."Dimension Code";
            DimensionValue.Code := BC14DimensionValue.Code;
            TransferFields(BC14DimensionValue, DimensionValue);
            DimensionValue.Insert(true);
        end;

        OnAfterMigrateDimensionValue(BC14DimensionValue, DimensionValue);
    end;

    local procedure TransferFields(BC14DimensionValue: Record "BC14 Dimension Value"; var DimensionValue: Record "Dimension Value")
    begin
        // Primary key fields (Dimension Code, Code) are assigned in the caller before this procedure.
        // Use Validate so any OnValidate business logic runs.
        DimensionValue.Validate(Name, BC14DimensionValue.Name);
        // "Dimension Value Type" and Totaling are direct-assigned together: OnValidate of
        // "Dimension Value Type" clears Totaling, and OnValidate of Totaling FieldErrors when
        // Type = Standard. The source values were already validated in BC14, so we carry them
        // forward verbatim and let any filter-shape recomputation happen on first use.
        DimensionValue."Dimension Value Type" := BC14DimensionValue."Value Type";
        DimensionValue.Totaling := BC14DimensionValue.Totaling;
        DimensionValue.Validate(Blocked, BC14DimensionValue.Blocked);
        DimensionValue.Validate("Consolidation Code", BC14DimensionValue."Consolidation Code");
        DimensionValue.Validate(Indentation, BC14DimensionValue.Indentation);
        DimensionValue.Validate("Global Dimension No.", BC14DimensionValue."Global Dimension No.");
        DimensionValue.Validate("Map-to IC Dimension Code", BC14DimensionValue."Map-to IC Dimension Code");
        DimensionValue.Validate("Map-to IC Dimension Value Code", BC14DimensionValue."Map-to IC Dimension Value Code");

        OnTransferDimensionValueCustomFields(BC14DimensionValue, DimensionValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateDimensionValues(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateDimensionValues(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateDimensionValue(BC14DimensionValue: Record "BC14 Dimension Value"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateDimensionValue(BC14DimensionValue: Record "BC14 Dimension Value"; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferDimensionValueCustomFields(BC14DimensionValue: Record "BC14 Dimension Value"; var DimensionValue: Record "Dimension Value")
    begin
    end;
}

