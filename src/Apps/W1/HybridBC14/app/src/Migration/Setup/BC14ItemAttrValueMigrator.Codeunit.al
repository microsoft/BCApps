// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Item.Attribute;

codeunit 46931 "BC14 Item Attr. Value Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Item Attribute Value";

    trigger OnRun()
    begin
        MigrateItemAttributeValue(Rec);
    end;

    var
        MigratorNameLbl: Label 'Item Attribute Value Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item Attribute Value", Database::"BC14 Item Attribute Value");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ItemAttributeValue: Record "BC14 Item Attribute Value";
    begin
        exit(not BC14ItemAttributeValue.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ItemAttributeValue: Record "BC14 Item Attribute Value";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ItemAttributeValue;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Item Attr. Value Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ItemAttributeValue: Record "BC14 Item Attribute Value";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Item Attribute Value", BC14ItemAttributeValue.Count()));
    end;

    internal procedure MigrateItemAttributeValue(BC14ItemAttributeValue: Record "BC14 Item Attribute Value")
    var
        ItemAttributeValue: Record "Item Attribute Value";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItemAttributeValue(BC14ItemAttributeValue, IsMigrated);
        if IsMigrated then
            exit;

        if ItemAttributeValue.Get(BC14ItemAttributeValue."Attribute ID", BC14ItemAttributeValue.ID) then begin
            TransferFields(BC14ItemAttributeValue, ItemAttributeValue);
            ItemAttributeValue.Modify();
        end else begin
            ItemAttributeValue.Init();
            TransferFields(BC14ItemAttributeValue, ItemAttributeValue);
            ItemAttributeValue.Insert();
        end;

        OnAfterMigrateItemAttributeValue(BC14ItemAttributeValue, ItemAttributeValue);
    end;

    local procedure TransferFields(BC14ItemAttributeValue: Record "BC14 Item Attribute Value"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ItemAttributeValue."Attribute ID" := BC14ItemAttributeValue."Attribute ID";
        ItemAttributeValue.ID := BC14ItemAttributeValue.ID;

        // Use Validate so any OnValidate business logic runs.
        ItemAttributeValue.Validate(Value, BC14ItemAttributeValue.Value);
        ItemAttributeValue.Validate("Numeric Value", BC14ItemAttributeValue."Numeric Value");
        ItemAttributeValue.Validate("Date Value", BC14ItemAttributeValue."Date Value");
        ItemAttributeValue.Validate(Blocked, BC14ItemAttributeValue.Blocked);

        OnTransferItemAttributeValueCustomFields(BC14ItemAttributeValue, ItemAttributeValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItemAttributeValue(BC14ItemAttributeValue: Record "BC14 Item Attribute Value"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItemAttributeValue(BC14ItemAttributeValue: Record "BC14 Item Attribute Value"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemAttributeValueCustomFields(BC14ItemAttributeValue: Record "BC14 Item Attribute Value"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
    end;
}

