// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Inventory.Item;

codeunit 50170 "BC14 Item Migrator" implements "IMasterMigrator"
{
    var
        MigratorNameLbl: Label 'Item Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetInventoryModuleEnabled());
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Item");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Item migration
    end;

    procedure IsRecordMigrated(var SourceRecordRef: RecordRef): Boolean
    var
        Item: Record Item;
        RecordKey: Text[250];
    begin
        RecordKey := GetSourceRecordKey(SourceRecordRef);
        // Only skip if target record already exists - failed records will be retried
        exit(Item.Get(RecordKey));
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14Item: Record "BC14 Item";
    begin
        SourceRecordRef.SetTable(BC14Item);
        exit(TryMigrateItem(BC14Item));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        NoFieldRef: FieldRef;
    begin
        NoFieldRef := SourceRecordRef.Field(1); // No. field
        exit(Format(NoFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14Item: Record "BC14 Item";
    begin
        exit(BC14Item.Count());
    end;

    [TryFunction]
    local procedure TryMigrateItem(BC14Item: Record "BC14 Item")
    begin
        MigrateItem(BC14Item);
    end;

    internal procedure MigrateItem(BC14Item: Record "BC14 Item")
    var
        Item: Record Item;
        IsNew: Boolean;
    begin
        IsNew := not Item.Get(BC14Item."No.");
        if IsNew then begin
            Item.Init();
            Item."No." := BC14Item."No.";
            Item.Description := BC14Item.Description;
            Item.Type := Enum::"Item Type".FromInteger(BC14Item.Type);
            Item.Insert(true);
        end;

        // Validate Base Unit of Measure after Insert because it triggers Item Unit of Measure
        // table validation which requires the Item record to already exist.
        if BC14Item."Base Unit of Measure" <> '' then
            Item.Validate("Base Unit of Measure", BC14Item."Base Unit of Measure");
        Item.Description := BC14Item.Description;
        Item.Type := Enum::"Item Type".FromInteger(BC14Item.Type);
        Item."Unit Price" := BC14Item."Unit Price";
        Item."Standard Cost" := BC14Item."Standard Cost";
        Item."Unit Cost" := BC14Item."Unit Cost";
        Item.Blocked := BC14Item.Blocked;
        Item.Validate("Inventory Posting Group", BC14Item."Inventory Posting Group");
        Item."Costing Method" := Enum::"Costing Method".FromInteger(BC14Item."Costing Method");
        Item."Net Weight" := BC14Item."Net Weight";
        Item."Unit Volume" := BC14Item."Unit Volume";

        OnTransferItemCustomFields(BC14Item, Item);

        Item.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferItemCustomFields(BC14Item: Record "BC14 Item"; var Item: Record Item)
    begin
    end;
}
