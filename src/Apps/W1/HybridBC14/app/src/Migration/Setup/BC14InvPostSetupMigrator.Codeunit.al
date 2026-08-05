// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Item;

codeunit 46898 "BC14 Inv. Post. Setup Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Inventory Posting Setup";

    trigger OnRun()
    begin
        MigrateInventoryPostingSetup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Inventory Posting Setup Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Inventory Posting Setup", Database::"BC14 Inventory Posting Setup");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup";
    begin
        exit(not BC14InventoryPostingSetup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14InventoryPostingSetup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Inv. Post. Setup Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Inventory Posting Setup", BC14InventoryPostingSetup.Count()));
    end;

    internal procedure MigrateInventoryPostingSetup(BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup")
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateInventoryPostingSetup(BC14InventoryPostingSetup, IsMigrated);
        if IsMigrated then
            exit;

        if InventoryPostingSetup.Get(BC14InventoryPostingSetup."Location Code", BC14InventoryPostingSetup."Invt. Posting Group Code") then begin
            TransferFields(BC14InventoryPostingSetup, InventoryPostingSetup);
            InventoryPostingSetup.Modify();
        end else begin
            InventoryPostingSetup.Init();
            TransferFields(BC14InventoryPostingSetup, InventoryPostingSetup);
            InventoryPostingSetup.Insert();
        end;

        OnAfterMigrateInventoryPostingSetup(BC14InventoryPostingSetup, InventoryPostingSetup);
    end;

    local procedure TransferFields(BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup"; var InventoryPostingSetup: Record "Inventory Posting Setup")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        InventoryPostingSetup."Location Code" := BC14InventoryPostingSetup."Location Code";
        InventoryPostingSetup."Invt. Posting Group Code" := BC14InventoryPostingSetup."Invt. Posting Group Code";

        // G/L Account FK fields: direct assignment. Inventory Posting Setup runs in the Setup phase,
        // before G/L Account is migrated in the Master phase, so Validate's TableRelation check would
        // always fail on a freshly-created target company. Accounts are verified lazily when posted.
        InventoryPostingSetup."Inventory Account" := BC14InventoryPostingSetup."Inventory Account";
        InventoryPostingSetup.Description := BC14InventoryPostingSetup.Description;
        InventoryPostingSetup."Inventory Account (Interim)" := BC14InventoryPostingSetup."Inventory Account (Interim)";
        InventoryPostingSetup."WIP Account" := BC14InventoryPostingSetup."WIP Account";
        InventoryPostingSetup."Material Variance Account" := BC14InventoryPostingSetup."Material Variance Account";
        InventoryPostingSetup."Capacity Variance Account" := BC14InventoryPostingSetup."Capacity Variance Account";
        InventoryPostingSetup."Mfg. Overhead Variance Account" := BC14InventoryPostingSetup."Mfg. Overhead Variance Account";
        InventoryPostingSetup."Cap. Overhead Variance Account" := BC14InventoryPostingSetup."Cap. Overhead Variance Account";
        InventoryPostingSetup."Subcontracted Variance Account" := BC14InventoryPostingSetup."Subcontracted Variance Account";
        InventoryPostingSetup."Mat. Non-Inv. Variance Acc." := BC14InventoryPostingSetup."Mat. Non-Inv. Variance Acc.";

        OnTransferInventoryPostingSetupCustomFields(BC14InventoryPostingSetup, InventoryPostingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateInventoryPostingSetup(BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateInventoryPostingSetup(BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup"; var InventoryPostingSetup: Record "Inventory Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferInventoryPostingSetupCustomFields(BC14InventoryPostingSetup: Record "BC14 Inventory Posting Setup"; var InventoryPostingSetup: Record "Inventory Posting Setup")
    begin
    end;
}
