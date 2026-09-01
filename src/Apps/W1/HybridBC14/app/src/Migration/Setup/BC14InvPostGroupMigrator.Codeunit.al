// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Item;

codeunit 46897 "BC14 Inv. Post. Group Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Inventory Posting Group";

    trigger OnRun()
    begin
        MigrateInventoryPostingGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Inventory Posting Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Inventory Posting Group", Database::"BC14 Inventory Posting Group");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateInventoryPostingGroups(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14InventoryPostingGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Inv. Post. Group Migrator");

        OnAfterMigrateInventoryPostingGroups(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Inventory Posting Group", BC14InventoryPostingGroup.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group";
    begin
        exit(not BC14InventoryPostingGroup.IsEmpty());
    end;

    internal procedure MigrateInventoryPostingGroup(BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group")
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateInventoryPostingGroup(BC14InventoryPostingGroup, IsMigrated);
        if IsMigrated then
            exit;

        if InventoryPostingGroup.Get(BC14InventoryPostingGroup.Code) then begin
            TransferFields(BC14InventoryPostingGroup, InventoryPostingGroup);
            InventoryPostingGroup.Modify(true);
        end else begin
            InventoryPostingGroup.Init();
            TransferFields(BC14InventoryPostingGroup, InventoryPostingGroup);
            InventoryPostingGroup.Insert(true);
        end;

        OnAfterMigrateInventoryPostingGroup(BC14InventoryPostingGroup, InventoryPostingGroup);
    end;

    local procedure TransferFields(BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group"; var InventoryPostingGroup: Record "Inventory Posting Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        InventoryPostingGroup.Code := BC14InventoryPostingGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        InventoryPostingGroup.Validate(Description, BC14InventoryPostingGroup.Description);

        OnTransferInventoryPostingGroupCustomFields(BC14InventoryPostingGroup, InventoryPostingGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateInventoryPostingGroups(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateInventoryPostingGroups(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateInventoryPostingGroup(BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateInventoryPostingGroup(BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group"; var InventoryPostingGroup: Record "Inventory Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferInventoryPostingGroupCustomFields(BC14InventoryPostingGroup: Record "BC14 Inventory Posting Group"; var InventoryPostingGroup: Record "Inventory Posting Group")
    begin
    end;
}

