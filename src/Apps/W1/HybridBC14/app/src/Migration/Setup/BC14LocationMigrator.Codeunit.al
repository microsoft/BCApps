// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Location;

codeunit 46918 "BC14 Location Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Location";

    trigger OnRun()
    begin
        MigrateLocation(Rec);
    end;

    var
        MigratorNameLbl: Label 'Location Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Location", Database::"BC14 Location");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14Location: Record "BC14 Location";
    begin
        exit(not BC14Location.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14Location: Record "BC14 Location";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14Location;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Location Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Location: Record "BC14 Location";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Location", BC14Location.Count()));
    end;

    internal procedure MigrateLocation(BC14Location: Record "BC14 Location")
    var
        Location: Record Location;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateLocation(BC14Location, IsMigrated);
        if IsMigrated then
            exit;

        if Location.Get(BC14Location.Code) then begin
            TransferFields(BC14Location, Location);
            Location.Modify();
        end else begin
            Location.Init();
            TransferFields(BC14Location, Location);
            Location.Insert();
        end;

        OnAfterMigrateLocation(BC14Location, Location);
    end;

    local procedure TransferFields(BC14Location: Record "BC14 Location"; var Location: Record Location)
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        Location.Code := BC14Location.Code;

        // Use Validate so any OnValidate business logic runs.
        Location.Validate(Name, BC14Location.Name);
        Location.Validate(Address, BC14Location.Address);
        Location.Validate("Address 2", BC14Location."Address 2");
        Location.Validate("Country/Region Code", BC14Location."Country/Region Code");
        Location.Validate("Post Code", BC14Location."Post Code");
        Location.Validate(City, BC14Location.City);
        Location.Validate(County, BC14Location.County);
        Location.Validate("Phone No.", BC14Location."Phone No.");
        Location.Validate(Contact, BC14Location.Contact);
        Location.Validate("Use As In-Transit", BC14Location."Use As In-Transit");
        Location.Validate("Require Receive", BC14Location."Require Receive");
        Location.Validate("Require Shipment", BC14Location."Require Shipment");
        Location.Validate("Require Put-away", BC14Location."Require Put-away");
        Location.Validate("Require Pick", BC14Location."Require Pick");
        Location.Validate("Bin Mandatory", BC14Location."Bin Mandatory");

        OnTransferLocationCustomFields(BC14Location, Location);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateLocation(BC14Location: Record "BC14 Location"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateLocation(BC14Location: Record "BC14 Location"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLocationCustomFields(BC14Location: Record "BC14 Location"; var Location: Record Location)
    begin
    end;
}

