// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.Address;

codeunit 46901 "BC14 Post Code Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Post Code";

    trigger OnRun()
    begin
        MigratePostCode(Rec);
    end;

    var
        MigratorNameLbl: Label 'Post Code Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Post Code", Database::"BC14 Post Code");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14PostCode: Record "BC14 Post Code";
    begin
        exit(not BC14PostCode.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14PostCode: Record "BC14 Post Code";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14PostCode;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Post Code Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14PostCode: Record "BC14 Post Code";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Post Code", BC14PostCode.Count()));
    end;

    internal procedure MigratePostCode(BC14PostCode: Record "BC14 Post Code")
    var
        PostCode: Record "Post Code";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigratePostCode(BC14PostCode, IsMigrated);
        if IsMigrated then
            exit;

        if PostCode.Get(BC14PostCode.Code, BC14PostCode.City) then begin
            TransferFields(BC14PostCode, PostCode);
            PostCode.Modify();
        end else begin
            PostCode.Init();
            TransferFields(BC14PostCode, PostCode);
            PostCode.Insert();
        end;

        OnAfterMigratePostCode(BC14PostCode, PostCode);
    end;

    local procedure TransferFields(BC14PostCode: Record "BC14 Post Code"; var PostCode: Record "Post Code")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        PostCode.Code := BC14PostCode.Code;
        PostCode.City := BC14PostCode.City;

        // Use Validate so any OnValidate business logic runs.
        PostCode.Validate("Search City", BC14PostCode."Search City");
        PostCode.Validate("Country/Region Code", BC14PostCode."Country/Region Code");
        PostCode.Validate(County, BC14PostCode.County);
        PostCode.Validate("Time Zone", BC14PostCode."Time Zone");

        OnTransferPostCodeCustomFields(BC14PostCode, PostCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigratePostCode(BC14PostCode: Record "BC14 Post Code"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigratePostCode(BC14PostCode: Record "BC14 Post Code"; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferPostCodeCustomFields(BC14PostCode: Record "BC14 Post Code"; var PostCode: Record "Post Code")
    begin
    end;
}

