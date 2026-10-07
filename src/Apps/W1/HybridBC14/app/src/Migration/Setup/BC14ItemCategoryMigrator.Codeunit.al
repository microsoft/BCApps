// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Item;

codeunit 46915 "BC14 Item Category Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Item Category";

    trigger OnRun()
    begin
        MigrateItemCategory(Rec);
    end;

    var
        MigratorNameLbl: Label 'Item Category Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item Category", Database::"BC14 Item Category");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ItemCategory: Record "BC14 Item Category";
    begin
        exit(not BC14ItemCategory.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ItemCategory: Record "BC14 Item Category";
        ItemCategory: Record "Item Category";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        // Pre-create empty rows (primary key only) for every source Code so that the
        // self-referencing "Parent Category" Validate in the main loop never fails because
        // of source iteration order — by the time we Validate, every potential parent
        // already exists in the target Item Category table.
        if BC14ItemCategory.FindSet() then
            repeat
                if not ItemCategory.Get(BC14ItemCategory.Code) then begin
                    ItemCategory.Init();
                    ItemCategory.Code := BC14ItemCategory.Code;
                    ItemCategory.Insert();
                end;
            until BC14ItemCategory.Next() = 0;
        Commit();

        SourceVariant := BC14ItemCategory;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Item Category Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ItemCategory: Record "BC14 Item Category";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Item Category", BC14ItemCategory.Count()));
    end;

    internal procedure MigrateItemCategory(BC14ItemCategory: Record "BC14 Item Category")
    var
        ItemCategory: Record "Item Category";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItemCategory(BC14ItemCategory, IsMigrated);
        if IsMigrated then
            exit;

        if ItemCategory.Get(BC14ItemCategory.Code) then begin
            TransferFields(BC14ItemCategory, ItemCategory);
            ItemCategory.Modify();
        end else begin
            ItemCategory.Init();
            TransferFields(BC14ItemCategory, ItemCategory);
            ItemCategory.Insert();
        end;

        OnAfterMigrateItemCategory(BC14ItemCategory, ItemCategory);
    end;

    local procedure TransferFields(BC14ItemCategory: Record "BC14 Item Category"; var ItemCategory: Record "Item Category")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ItemCategory.Code := BC14ItemCategory.Code;

        // Use Validate so any OnValidate business logic runs.
        ItemCategory.Validate(Description, BC14ItemCategory.Description);
        ItemCategory.Validate("Parent Category", BC14ItemCategory."Parent Category");
        ItemCategory.Validate("Presentation Order", BC14ItemCategory."Presentation Order");
        ItemCategory.Validate(Indentation, BC14ItemCategory.Indentation);

        OnTransferItemCategoryCustomFields(BC14ItemCategory, ItemCategory);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItemCategory(BC14ItemCategory: Record "BC14 Item Category"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItemCategory(BC14ItemCategory: Record "BC14 Item Category"; var ItemCategory: Record "Item Category")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemCategoryCustomFields(BC14ItemCategory: Record "BC14 Item Category"; var ItemCategory: Record "Item Category")
    begin
    end;
}

