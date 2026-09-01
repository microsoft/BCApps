// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Tracking;

codeunit 46916 "BC14 Item Trk. Code Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Item Tracking Code";

    trigger OnRun()
    begin
        MigrateItemTrackingCode(Rec);
    end;

    var
        MigratorNameLbl: Label 'Item Tracking Code Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item Tracking Code", Database::"BC14 Item Tracking Code");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ItemTrackingCode: Record "BC14 Item Tracking Code";
    begin
        exit(not BC14ItemTrackingCode.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ItemTrackingCode: Record "BC14 Item Tracking Code";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ItemTrackingCode;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Item Trk. Code Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ItemTrackingCode: Record "BC14 Item Tracking Code";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Item Tracking Code", BC14ItemTrackingCode.Count()));
    end;

    internal procedure MigrateItemTrackingCode(BC14ItemTrackingCode: Record "BC14 Item Tracking Code")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItemTrackingCode(BC14ItemTrackingCode, IsMigrated);
        if IsMigrated then
            exit;

        if ItemTrackingCode.Get(BC14ItemTrackingCode.Code) then begin
            TransferFields(BC14ItemTrackingCode, ItemTrackingCode);
            ItemTrackingCode.Modify();
        end else begin
            ItemTrackingCode.Init();
            TransferFields(BC14ItemTrackingCode, ItemTrackingCode);
            ItemTrackingCode.Insert();
        end;

        OnAfterMigrateItemTrackingCode(BC14ItemTrackingCode, ItemTrackingCode);
    end;

    local procedure TransferFields(BC14ItemTrackingCode: Record "BC14 Item Tracking Code"; var ItemTrackingCode: Record "Item Tracking Code")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ItemTrackingCode.Code := BC14ItemTrackingCode.Code;

        // Item Tracking Code's UI design locks every sub-flag once the master "SN/Lot Specific
        // Tracking" flag is true: each sub-flag's OnValidate does TestField("...Specific
        // Tracking", false) and rejects any write — even rewriting the same value. Direct-assign
        // all flags so the migrator can faithfully copy whatever combination the source had,
        // without tripping these interactive guard rails.
        ItemTrackingCode.Validate(Description, BC14ItemTrackingCode.Description);
        ItemTrackingCode."SN Specific Tracking" := BC14ItemTrackingCode."SN Specific Tracking";
        ItemTrackingCode."SN Sales Inbound Tracking" := BC14ItemTrackingCode."SN Sales Inbound Tracking";
        ItemTrackingCode."SN Sales Outbound Tracking" := BC14ItemTrackingCode."SN Sales Outbound Tracking";
        ItemTrackingCode."SN Purchase Inbound Tracking" := BC14ItemTrackingCode."SN Purchase Inbound Tracking";
        ItemTrackingCode."SN Purchase Outbound Tracking" := BC14ItemTrackingCode."SN Purchase Outbound Tracking";
        ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking" := BC14ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking";
        ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking" := BC14ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking";
        ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking" := BC14ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking";
        ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking" := BC14ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking";
        ItemTrackingCode."SN Transfer Tracking" := BC14ItemTrackingCode."SN Transfer Tracking";
        ItemTrackingCode."Lot Specific Tracking" := BC14ItemTrackingCode."Lot Specific Tracking";
        ItemTrackingCode."Lot Sales Inbound Tracking" := BC14ItemTrackingCode."Lot Sales Inbound Tracking";
        ItemTrackingCode."Lot Sales Outbound Tracking" := BC14ItemTrackingCode."Lot Sales Outbound Tracking";
        ItemTrackingCode."Lot Purchase Inbound Tracking" := BC14ItemTrackingCode."Lot Purchase Inbound Tracking";
        ItemTrackingCode."Lot Purchase Outbound Tracking" := BC14ItemTrackingCode."Lot Purchase Outbound Tracking";
        ItemTrackingCode."Lot Transfer Tracking" := BC14ItemTrackingCode."Lot Transfer Tracking";
        ItemTrackingCode."SN Warehouse Tracking" := BC14ItemTrackingCode."SN Warehouse Tracking";
        ItemTrackingCode."Lot Warehouse Tracking" := BC14ItemTrackingCode."Lot Warehouse Tracking";

        OnTransferItemTrackingCodeCustomFields(BC14ItemTrackingCode, ItemTrackingCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItemTrackingCode(BC14ItemTrackingCode: Record "BC14 Item Tracking Code"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItemTrackingCode(BC14ItemTrackingCode: Record "BC14 Item Tracking Code"; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemTrackingCodeCustomFields(BC14ItemTrackingCode: Record "BC14 Item Tracking Code"; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;
}

