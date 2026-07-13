// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Item;

codeunit 46923 "BC14 Item Disc. Grp. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Item Discount Group";

    trigger OnRun()
    begin
        MigrateItemDiscountGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Item Discount Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item Discount Group", Database::"BC14 Item Discount Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ItemDiscountGroup: Record "BC14 Item Discount Group";
    begin
        exit(not BC14ItemDiscountGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ItemDiscountGroup: Record "BC14 Item Discount Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ItemDiscountGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Item Disc. Grp. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ItemDiscountGroup: Record "BC14 Item Discount Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Item Discount Group", BC14ItemDiscountGroup.Count()));
    end;

    internal procedure MigrateItemDiscountGroup(BC14ItemDiscountGroup: Record "BC14 Item Discount Group")
    var
        ItemDiscountGroup: Record "Item Discount Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItemDiscountGroup(BC14ItemDiscountGroup, IsMigrated);
        if IsMigrated then
            exit;

        if ItemDiscountGroup.Get(BC14ItemDiscountGroup.Code) then begin
            TransferFields(BC14ItemDiscountGroup, ItemDiscountGroup);
            ItemDiscountGroup.Modify();
        end else begin
            ItemDiscountGroup.Init();
            TransferFields(BC14ItemDiscountGroup, ItemDiscountGroup);
            ItemDiscountGroup.Insert();
        end;

        OnAfterMigrateItemDiscountGroup(BC14ItemDiscountGroup, ItemDiscountGroup);
    end;

    local procedure TransferFields(BC14ItemDiscountGroup: Record "BC14 Item Discount Group"; var ItemDiscountGroup: Record "Item Discount Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ItemDiscountGroup.Code := BC14ItemDiscountGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        ItemDiscountGroup.Validate(Description, BC14ItemDiscountGroup.Description);

        OnTransferItemDiscountGroupCustomFields(BC14ItemDiscountGroup, ItemDiscountGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItemDiscountGroup(BC14ItemDiscountGroup: Record "BC14 Item Discount Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItemDiscountGroup(BC14ItemDiscountGroup: Record "BC14 Item Discount Group"; var ItemDiscountGroup: Record "Item Discount Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemDiscountGroupCustomFields(BC14ItemDiscountGroup: Record "BC14 Item Discount Group"; var ItemDiscountGroup: Record "Item Discount Group")
    begin
    end;
}

