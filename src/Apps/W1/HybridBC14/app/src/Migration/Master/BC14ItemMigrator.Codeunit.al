// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Item;

codeunit 46870 "BC14 Item Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Item";

    trigger OnRun()
    begin
        MigrateItem(Rec);
    end;

    var
        MigratorNameLbl: Label 'Item Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item", Database::"BC14 Item");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetInventoryModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14Item: Record "BC14 Item";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItems(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14Item;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Item Migrator");

        OnAfterMigrateItems(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Item: Record "BC14 Item";
        Item: Record Item;
        TotalCount: Integer;
    begin
        TotalCount := BC14Item.Count();
        if TotalCount = 0 then
            exit(0);
        exit(Round((TotalCount - Item.Count()) / TotalCount * 100, 1));
    end;

    internal procedure MigrateItem(BC14Item: Record "BC14 Item")
    var
        Item: Record Item;
        IsNew: Boolean;
        IsMigrated: Boolean;
        PostingFieldsChanged: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItem(BC14Item, IsMigrated);
        if IsMigrated then
            exit;

        IsNew := not Item.Get(BC14Item."No.");
        if IsNew then begin
            Item.Init();
            Item."No." := BC14Item."No.";
        end;
        Item.Description := BC14Item.Description;
        Item.Type := Enum::"Item Type".FromInteger(BC14Item.Type);
        Item."Unit Price" := BC14Item."Unit Price";
        Item."Standard Cost" := BC14Item."Standard Cost";
        Item."Unit Cost" := BC14Item."Unit Cost";
        Item.Blocked := BC14Item.Blocked;
        Item."Costing Method" := Enum::"Costing Method".FromInteger(BC14Item."Costing Method");
        Item."Net Weight" := BC14Item."Net Weight";
        Item."Unit Volume" := BC14Item."Unit Volume";

        OnTransferItemCustomFields(BC14Item, Item);

        if IsNew then
            Item.Insert(true)
        else
            Item.Modify(true);

        PostingFieldsChanged := false;
        if (BC14Item."Inventory Posting Group" <> '') and (Item."Inventory Posting Group" <> BC14Item."Inventory Posting Group") then begin
            Item.Validate("Inventory Posting Group", BC14Item."Inventory Posting Group");
            PostingFieldsChanged := true;
        end;
        if (BC14Item."Gen. Prod. Posting Group" <> '') and (Item."Gen. Prod. Posting Group" <> BC14Item."Gen. Prod. Posting Group") then begin
            Item.Validate("Gen. Prod. Posting Group", BC14Item."Gen. Prod. Posting Group");
            PostingFieldsChanged := true;
        end;
        if (BC14Item."Base Unit of Measure" <> '') and (Item."Base Unit of Measure" <> BC14Item."Base Unit of Measure") then begin
            Item.Validate("Base Unit of Measure", BC14Item."Base Unit of Measure");
            PostingFieldsChanged := true;
        end;
        if PostingFieldsChanged then
            Item.Modify();

        OnAfterMigrateItem(BC14Item, Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItems(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItems(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItem(BC14Item: Record "BC14 Item"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItem(BC14Item: Record "BC14 Item"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemCustomFields(BC14Item: Record "BC14 Item"; var Item: Record Item)
    begin
    end;
}

