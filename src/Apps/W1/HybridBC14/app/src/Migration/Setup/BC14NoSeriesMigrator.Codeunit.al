// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.NoSeries;

codeunit 46928 "BC14 No. Series Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 No. Series";

    trigger OnRun()
    begin
        MigrateNoSeries(Rec);
    end;

    var
        MigratorNameLbl: Label 'No. Series Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"No. Series", Database::"BC14 No. Series");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14NoSeries: Record "BC14 No. Series";
    begin
        exit(not BC14NoSeries.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14NoSeries: Record "BC14 No. Series";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14NoSeries;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 No. Series Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14NoSeries: Record "BC14 No. Series";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 No. Series", BC14NoSeries.Count()));
    end;

    internal procedure MigrateNoSeries(BC14NoSeries: Record "BC14 No. Series")
    var
        NoSeries: Record "No. Series";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateNoSeries(BC14NoSeries, IsMigrated);
        if IsMigrated then
            exit;

        if NoSeries.Get(BC14NoSeries.Code) then begin
            TransferFields(BC14NoSeries, NoSeries);
            NoSeries.Modify();
        end else begin
            NoSeries.Init();
            TransferFields(BC14NoSeries, NoSeries);
            NoSeries.Insert();
        end;

        OnAfterMigrateNoSeries(BC14NoSeries, NoSeries);
    end;

    local procedure TransferFields(BC14NoSeries: Record "BC14 No. Series"; var NoSeries: Record "No. Series")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        NoSeries.Code := BC14NoSeries.Code;

        // Use Validate so any OnValidate business logic runs.
        NoSeries.Validate(Description, BC14NoSeries.Description);
        NoSeries.Validate("Default Nos.", BC14NoSeries."Default Nos.");
        NoSeries.Validate("Manual Nos.", BC14NoSeries."Manual Nos.");
        NoSeries.Validate("Date Order", BC14NoSeries."Date Order");

        OnTransferNoSeriesCustomFields(BC14NoSeries, NoSeries);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateNoSeries(BC14NoSeries: Record "BC14 No. Series"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateNoSeries(BC14NoSeries: Record "BC14 No. Series"; var NoSeries: Record "No. Series")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferNoSeriesCustomFields(BC14NoSeries: Record "BC14 No. Series"; var NoSeries: Record "No. Series")
    begin
    end;
}

