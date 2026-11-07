// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.Address;

codeunit 46900 "BC14 Country/Region Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Country/Region";

    trigger OnRun()
    begin
        MigrateCountryRegion(Rec);
    end;

    var
        MigratorNameLbl: Label 'Country/Region Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Country/Region", Database::"BC14 Country/Region");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CountryRegion: Record "BC14 Country/Region";
    begin
        exit(not BC14CountryRegion.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14CountryRegion;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Country/Region Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CountryRegion: Record "BC14 Country/Region";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Country/Region", BC14CountryRegion.Count()));
    end;

    internal procedure MigrateCountryRegion(BC14CountryRegion: Record "BC14 Country/Region")
    var
        CountryRegion: Record "Country/Region";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCountryRegion(BC14CountryRegion, IsMigrated);
        if IsMigrated then
            exit;

        if CountryRegion.Get(BC14CountryRegion.Code) then begin
            TransferFields(BC14CountryRegion, CountryRegion);
            CountryRegion.Modify();
        end else begin
            CountryRegion.Init();
            TransferFields(BC14CountryRegion, CountryRegion);
            CountryRegion.Insert();
        end;

        OnAfterMigrateCountryRegion(BC14CountryRegion, CountryRegion);
    end;

    local procedure TransferFields(BC14CountryRegion: Record "BC14 Country/Region"; var CountryRegion: Record "Country/Region")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        CountryRegion.Code := BC14CountryRegion.Code;

        // Use Validate so any OnValidate business logic runs.
        CountryRegion.Validate(Name, BC14CountryRegion.Name);
        CountryRegion.Validate("ISO Code", BC14CountryRegion."ISO Code");
        CountryRegion.Validate("ISO Numeric Code", BC14CountryRegion."ISO Numeric Code");
        CountryRegion.Validate("EU Country/Region Code", BC14CountryRegion."EU Country/Region Code");
        CountryRegion.Validate("Intrastat Code", BC14CountryRegion."Intrastat Code");
        CountryRegion.Validate("Address Format", BC14CountryRegion."Address Format");
        CountryRegion.Validate("Contact Address Format", BC14CountryRegion."Contact Address Format");
        CountryRegion.Validate("VAT Scheme", BC14CountryRegion."VAT Scheme");
        CountryRegion.Validate("County Name", BC14CountryRegion."County Name");

        OnTransferCountryRegionCustomFields(BC14CountryRegion, CountryRegion);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCountryRegion(BC14CountryRegion: Record "BC14 Country/Region"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCountryRegion(BC14CountryRegion: Record "BC14 Country/Region"; var CountryRegion: Record "Country/Region")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCountryRegionCustomFields(BC14CountryRegion: Record "BC14 Country/Region"; var CountryRegion: Record "Country/Region")
    begin
    end;
}

