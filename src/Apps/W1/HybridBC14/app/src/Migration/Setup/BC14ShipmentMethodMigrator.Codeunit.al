// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.Shipping;

codeunit 46913 "BC14 Shipment Method Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Shipment Method";

    trigger OnRun()
    begin
        MigrateShipmentMethod(Rec);
    end;

    var
        MigratorNameLbl: Label 'Shipment Method Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Shipment Method", Database::"BC14 Shipment Method");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ShipmentMethod: Record "BC14 Shipment Method";
    begin
        exit(not BC14ShipmentMethod.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ShipmentMethod: Record "BC14 Shipment Method";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ShipmentMethod;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Shipment Method Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ShipmentMethod: Record "BC14 Shipment Method";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Shipment Method", BC14ShipmentMethod.Count()));
    end;

    internal procedure MigrateShipmentMethod(BC14ShipmentMethod: Record "BC14 Shipment Method")
    var
        ShipmentMethod: Record "Shipment Method";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateShipmentMethod(BC14ShipmentMethod, IsMigrated);
        if IsMigrated then
            exit;

        if ShipmentMethod.Get(BC14ShipmentMethod.Code) then begin
            TransferFields(BC14ShipmentMethod, ShipmentMethod);
            ShipmentMethod.Modify();
        end else begin
            ShipmentMethod.Init();
            TransferFields(BC14ShipmentMethod, ShipmentMethod);
            ShipmentMethod.Insert();
        end;

        OnAfterMigrateShipmentMethod(BC14ShipmentMethod, ShipmentMethod);
    end;

    local procedure TransferFields(BC14ShipmentMethod: Record "BC14 Shipment Method"; var ShipmentMethod: Record "Shipment Method")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ShipmentMethod.Code := BC14ShipmentMethod.Code;

        // Use Validate so any OnValidate business logic runs.
        ShipmentMethod.Validate(Description, BC14ShipmentMethod.Description);

        OnTransferShipmentMethodCustomFields(BC14ShipmentMethod, ShipmentMethod);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateShipmentMethod(BC14ShipmentMethod: Record "BC14 Shipment Method"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateShipmentMethod(BC14ShipmentMethod: Record "BC14 Shipment Method"; var ShipmentMethod: Record "Shipment Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferShipmentMethodCustomFields(BC14ShipmentMethod: Record "BC14 Shipment Method"; var ShipmentMethod: Record "Shipment Method")
    begin
    end;
}

