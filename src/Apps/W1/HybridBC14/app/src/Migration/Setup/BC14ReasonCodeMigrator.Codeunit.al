// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.AuditCodes;

codeunit 46919 "BC14 Reason Code Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Reason Code";

    trigger OnRun()
    begin
        MigrateReasonCode(Rec);
    end;

    var
        MigratorNameLbl: Label 'Reason Code Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Reason Code", Database::"BC14 Reason Code");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ReasonCode: Record "BC14 Reason Code";
    begin
        exit(not BC14ReasonCode.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ReasonCode: Record "BC14 Reason Code";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ReasonCode;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Reason Code Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ReasonCode: Record "BC14 Reason Code";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Reason Code", BC14ReasonCode.Count()));
    end;

    internal procedure MigrateReasonCode(BC14ReasonCode: Record "BC14 Reason Code")
    var
        ReasonCode: Record "Reason Code";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateReasonCode(BC14ReasonCode, IsMigrated);
        if IsMigrated then
            exit;

        if ReasonCode.Get(BC14ReasonCode.Code) then begin
            TransferFields(BC14ReasonCode, ReasonCode);
            ReasonCode.Modify();
        end else begin
            ReasonCode.Init();
            TransferFields(BC14ReasonCode, ReasonCode);
            ReasonCode.Insert();
        end;

        OnAfterMigrateReasonCode(BC14ReasonCode, ReasonCode);
    end;

    local procedure TransferFields(BC14ReasonCode: Record "BC14 Reason Code"; var ReasonCode: Record "Reason Code")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ReasonCode.Code := BC14ReasonCode.Code;

        // Use Validate so any OnValidate business logic runs.
        ReasonCode.Validate(Description, BC14ReasonCode.Description);

        OnTransferReasonCodeCustomFields(BC14ReasonCode, ReasonCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateReasonCode(BC14ReasonCode: Record "BC14 Reason Code"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateReasonCode(BC14ReasonCode: Record "BC14 Reason Code"; var ReasonCode: Record "Reason Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferReasonCodeCustomFields(BC14ReasonCode: Record "BC14 Reason Code"; var ReasonCode: Record "Reason Code")
    begin
    end;
}

