// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Customer;

codeunit 46934 "BC14 Ship-to Address Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Ship-to Address";

    trigger OnRun()
    begin
        MigrateShipToAddress(Rec);
    end;

    var
        MigratorNameLbl: Label 'Ship-to Address Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Ship-to Address", Database::"BC14 Ship-to Address");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ShiptoAddress: Record "BC14 Ship-to Address";
    begin
        exit(not BC14ShiptoAddress.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ShiptoAddress: Record "BC14 Ship-to Address";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ShiptoAddress;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Ship-to Address Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ShiptoAddress: Record "BC14 Ship-to Address";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Ship-to Address", BC14ShiptoAddress.Count()));
    end;

    internal procedure MigrateShipToAddress(BC14ShiptoAddress: Record "BC14 Ship-to Address")
    var
        ShipToAddress: Record "Ship-to Address";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateShipToAddress(BC14ShiptoAddress, IsMigrated);
        if IsMigrated then
            exit;

        if ShipToAddress.Get(BC14ShiptoAddress."Customer No.", BC14ShiptoAddress.Code) then begin
            TransferFields(BC14ShiptoAddress, ShipToAddress);
            ShipToAddress.Modify();
        end else begin
            ShipToAddress.Init();
            TransferFields(BC14ShiptoAddress, ShipToAddress);
            ShipToAddress.Insert();
        end;

        OnAfterMigrateShipToAddress(BC14ShiptoAddress, ShipToAddress);
    end;

    local procedure TransferFields(BC14ShiptoAddress: Record "BC14 Ship-to Address"; var ShipToAddress: Record "Ship-to Address")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ShipToAddress."Customer No." := BC14ShiptoAddress."Customer No.";
        ShipToAddress.Code := BC14ShiptoAddress.Code;

        // Use Validate so any OnValidate business logic runs.
        ShipToAddress.Validate(Name, BC14ShiptoAddress.Name);
        ShipToAddress.Validate("Name 2", BC14ShiptoAddress."Name 2");
        ShipToAddress.Validate(Address, BC14ShiptoAddress.Address);
        ShipToAddress.Validate("Address 2", BC14ShiptoAddress."Address 2");
        ShipToAddress.Validate("Country/Region Code", BC14ShiptoAddress."Country/Region Code");
        ShipToAddress.Validate("Post Code", BC14ShiptoAddress."Post Code");
        ShipToAddress.Validate(City, BC14ShiptoAddress.City);
        ShipToAddress.Validate(County, BC14ShiptoAddress.County);
        ShipToAddress.Validate(Contact, BC14ShiptoAddress.Contact);
        ShipToAddress.Validate("Phone No.", BC14ShiptoAddress."Phone No.");
        ShipToAddress.Validate("Telex No.", BC14ShiptoAddress."Telex No.");
        ShipToAddress.Validate("Fax No.", BC14ShiptoAddress."Fax No.");
        ShipToAddress.Validate("E-Mail", BC14ShiptoAddress."E-Mail");
        ShipToAddress.Validate("Home Page", BC14ShiptoAddress."Home Page");
        ShipToAddress.Validate("Location Code", BC14ShiptoAddress."Location Code");
        ShipToAddress.Validate("Shipment Method Code", BC14ShiptoAddress."Shipment Method Code");
        ShipToAddress.Validate("Tax Area Code", BC14ShiptoAddress."Tax Area Code");
        ShipToAddress.Validate("Tax Liable", BC14ShiptoAddress."Tax Liable");

        OnTransferShipToAddressCustomFields(BC14ShiptoAddress, ShipToAddress);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateShipToAddress(BC14ShiptoAddress: Record "BC14 Ship-to Address"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateShipToAddress(BC14ShiptoAddress: Record "BC14 Ship-to Address"; var ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferShipToAddressCustomFields(BC14ShiptoAddress: Record "BC14 Ship-to Address"; var ShipToAddress: Record "Ship-to Address")
    begin
    end;
}

