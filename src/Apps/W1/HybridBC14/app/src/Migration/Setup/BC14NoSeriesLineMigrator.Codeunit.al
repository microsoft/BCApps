// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.NoSeries;

codeunit 46929 "BC14 No. Series Line Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 No. Series Line";

    trigger OnRun()
    begin
        MigrateNoSeriesLine(Rec);
    end;

    var
        MigratorNameLbl: Label 'No. Series Line Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"No. Series Line", Database::"BC14 No. Series Line");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14NoSeriesLine: Record "BC14 No. Series Line";
    begin
        exit(not BC14NoSeriesLine.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14NoSeriesLine: Record "BC14 No. Series Line";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14NoSeriesLine;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 No. Series Line Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14NoSeriesLine: Record "BC14 No. Series Line";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 No. Series Line", BC14NoSeriesLine.Count()));
    end;

    internal procedure MigrateNoSeriesLine(BC14NoSeriesLine: Record "BC14 No. Series Line")
    var
        NoSeriesLine: Record "No. Series Line";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateNoSeriesLine(BC14NoSeriesLine, IsMigrated);
        if IsMigrated then
            exit;

        if NoSeriesLine.Get(BC14NoSeriesLine."Series Code", BC14NoSeriesLine."Line No.") then begin
            TransferFields(BC14NoSeriesLine, NoSeriesLine);
            NoSeriesLine.Modify();
        end else begin
            NoSeriesLine.Init();
            TransferFields(BC14NoSeriesLine, NoSeriesLine);
            NoSeriesLine.Insert();
        end;

        OnAfterMigrateNoSeriesLine(BC14NoSeriesLine, NoSeriesLine);
    end;

    local procedure TransferFields(BC14NoSeriesLine: Record "BC14 No. Series Line"; var NoSeriesLine: Record "No. Series Line")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        NoSeriesLine."Series Code" := BC14NoSeriesLine."Series Code";
        NoSeriesLine."Line No." := BC14NoSeriesLine."Line No.";

        // Use Validate so any OnValidate business logic runs.
        NoSeriesLine.Validate("Starting Date", BC14NoSeriesLine."Starting Date");
        NoSeriesLine.Validate("Starting No.", BC14NoSeriesLine."Starting No.");
        NoSeriesLine.Validate("Ending No.", BC14NoSeriesLine."Ending No.");
        NoSeriesLine.Validate("Warning No.", BC14NoSeriesLine."Warning No.");
        NoSeriesLine.Validate("Increment-by No.", BC14NoSeriesLine."Increment-by No.");
        NoSeriesLine.Validate("Last No. Used", BC14NoSeriesLine."Last No. Used");
        NoSeriesLine.Validate(Open, BC14NoSeriesLine.Open);
        NoSeriesLine.Validate("Last Date Used", BC14NoSeriesLine."Last Date Used");

        OnTransferNoSeriesLineCustomFields(BC14NoSeriesLine, NoSeriesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateNoSeriesLine(BC14NoSeriesLine: Record "BC14 No. Series Line"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateNoSeriesLine(BC14NoSeriesLine: Record "BC14 No. Series Line"; var NoSeriesLine: Record "No. Series Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferNoSeriesLineCustomFields(BC14NoSeriesLine: Record "BC14 No. Series Line"; var NoSeriesLine: Record "No. Series Line")
    begin
    end;
}

