// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Item.Attribute;

codeunit 46930 "BC14 Item Attribute Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Item Attribute";

    trigger OnRun()
    begin
        MigrateItemAttribute(Rec);
    end;

    var
        MigratorNameLbl: Label 'Item Attribute Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item Attribute", Database::"BC14 Item Attribute");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14ItemAttribute: Record "BC14 Item Attribute";
    begin
        exit(not BC14ItemAttribute.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14ItemAttribute: Record "BC14 Item Attribute";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14ItemAttribute;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Item Attribute Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ItemAttribute: Record "BC14 Item Attribute";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Item Attribute", BC14ItemAttribute.Count()));
    end;

    internal procedure MigrateItemAttribute(BC14ItemAttribute: Record "BC14 Item Attribute")
    var
        ItemAttribute: Record "Item Attribute";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItemAttribute(BC14ItemAttribute, IsMigrated);
        if IsMigrated then
            exit;

        if ItemAttribute.Get(BC14ItemAttribute.ID) then begin
            TransferFields(BC14ItemAttribute, ItemAttribute);
            ItemAttribute.Modify();
        end else begin
            ItemAttribute.Init();
            TransferFields(BC14ItemAttribute, ItemAttribute);
            ItemAttribute.Insert();
        end;

        OnAfterMigrateItemAttribute(BC14ItemAttribute, ItemAttribute);
    end;

    local procedure TransferFields(BC14ItemAttribute: Record "BC14 Item Attribute"; var ItemAttribute: Record "Item Attribute")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        ItemAttribute.ID := BC14ItemAttribute.ID;

        // Use Validate so any OnValidate business logic runs.
        ItemAttribute.Validate(Name, BC14ItemAttribute.Name);
        ItemAttribute.Validate(Type, BC14ItemAttribute.Type);
        ItemAttribute.Validate("Unit of Measure", BC14ItemAttribute."Unit of Measure");
        ItemAttribute.Validate(Blocked, BC14ItemAttribute.Blocked);

        OnTransferItemAttributeCustomFields(BC14ItemAttribute, ItemAttribute);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItemAttribute(BC14ItemAttribute: Record "BC14 Item Attribute"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItemAttribute(BC14ItemAttribute: Record "BC14 Item Attribute"; var ItemAttribute: Record "Item Attribute")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemAttributeCustomFields(BC14ItemAttribute: Record "BC14 Item Attribute"; var ItemAttribute: Record "Item Attribute")
    begin
    end;
}

