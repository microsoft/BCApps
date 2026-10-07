// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using System.Globalization;

codeunit 46902 "BC14 Language Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Language";

    trigger OnRun()
    begin
        MigrateLanguage(Rec);
    end;

    var
        MigratorNameLbl: Label 'Language Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Language", Database::"BC14 Language");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14Language: Record "BC14 Language";
    begin
        exit(not BC14Language.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14Language: Record "BC14 Language";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14Language;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Language Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Language: Record "BC14 Language";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Language", BC14Language.Count()));
    end;

    internal procedure MigrateLanguage(BC14Language: Record "BC14 Language")
    var
        Language: Record Language;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateLanguage(BC14Language, IsMigrated);
        if IsMigrated then
            exit;

        if Language.Get(BC14Language.Code) then begin
            TransferFields(BC14Language, Language);
            Language.Modify();
        end else begin
            Language.Init();
            TransferFields(BC14Language, Language);
            Language.Insert();
        end;

        OnAfterMigrateLanguage(BC14Language, Language);
    end;

    local procedure TransferFields(BC14Language: Record "BC14 Language"; var Language: Record Language)
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        Language.Code := BC14Language.Code;

        // Use Validate so any OnValidate business logic runs.
        Language.Validate(Name, BC14Language.Name);
        Language.Validate("Windows Language ID", BC14Language."Windows Language ID");

        OnTransferLanguageCustomFields(BC14Language, Language);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateLanguage(BC14Language: Record "BC14 Language"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateLanguage(BC14Language: Record "BC14 Language"; var Language: Record Language)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLanguageCustomFields(BC14Language: Record "BC14 Language"; var Language: Record Language)
    begin
    end;
}

