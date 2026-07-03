// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.AuditCodes;

codeunit 46920 "BC14 Source Code Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Source Code";

    trigger OnRun()
    begin
        MigrateSourceCode(Rec);
    end;

    var
        MigratorNameLbl: Label 'Source Code Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Source Code", Database::"BC14 Source Code");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14SourceCode: Record "BC14 Source Code";
    begin
        exit(not BC14SourceCode.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14SourceCode: Record "BC14 Source Code";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14SourceCode;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Source Code Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14SourceCode: Record "BC14 Source Code";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Source Code", BC14SourceCode.Count()));
    end;

    internal procedure MigrateSourceCode(BC14SourceCode: Record "BC14 Source Code")
    var
        SourceCode: Record "Source Code";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateSourceCode(BC14SourceCode, IsMigrated);
        if IsMigrated then
            exit;

        if SourceCode.Get(BC14SourceCode.Code) then begin
            TransferFields(BC14SourceCode, SourceCode);
            SourceCode.Modify();
        end else begin
            SourceCode.Init();
            TransferFields(BC14SourceCode, SourceCode);
            SourceCode.Insert();
        end;

        OnAfterMigrateSourceCode(BC14SourceCode, SourceCode);
    end;

    local procedure TransferFields(BC14SourceCode: Record "BC14 Source Code"; var SourceCode: Record "Source Code")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        SourceCode.Code := BC14SourceCode.Code;

        // Use Validate so any OnValidate business logic runs.
        SourceCode.Validate(Description, BC14SourceCode.Description);

        OnTransferSourceCodeCustomFields(BC14SourceCode, SourceCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateSourceCode(BC14SourceCode: Record "BC14 Source Code"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateSourceCode(BC14SourceCode: Record "BC14 Source Code"; var SourceCode: Record "Source Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferSourceCodeCustomFields(BC14SourceCode: Record "BC14 Source Code"; var SourceCode: Record "Source Code")
    begin
    end;
}

