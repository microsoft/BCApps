// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using System.Environment.Configuration;
using System.Reflection;
using System.Upgrade;

codeunit 20509 "Subc. Data Migration"
{
    Access = Internal;

    internal procedure MigrateRenumberedData()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetRenumberedDataMigrationTag()) then begin
            LogMigrationNotInitiated(MigrationAlreadyCompletedLbl);
            exit;
        end;

        LogMigrationInitiated();
        MigrateWorksheetFields();
        MigrateRenumberedTables();
        MigrateInventoryFields();
        MigrateManufacturingFields();
        MigratePurchaseFields();
        MigrateSetupFields();
        MigrateTransferFields();
        MigrateWarehouseFields();

        SetRenumberedDataMigrationTag();
    end;

    local procedure LogMigrationInitiated()
    begin
        Session.LogMessage('', MigrationInitiatedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
    end;

    local procedure LogMigrationNotInitiated(Reason: Text)
    begin
        Session.LogMessage('', StrSubstNo(MigrationNotInitiatedMsg, Reason), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
    end;

    internal procedure SetRenumberedDataMigrationTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetRenumberedDataMigrationTag()) then
            UpgradeTag.SetUpgradeTag(GetRenumberedDataMigrationTag());
    end;

    local procedure MigrateRenumberedTables()
    var
        FieldIds: List of [Integer];
    begin
        SetFieldIds(FieldIds, '1,2,3,4,5,6,7,8,9,10,20,30');
        MigrateTableData(Database::"Subcontractor Price", FieldIds);

        SetFieldIds(FieldIds, '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21');
        MigrateTableData(Database::"Subcontractor WIP Ledger Entry", FieldIds);
    end;

    local procedure MigrateWorksheetFields()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(Database::"Req. Wksh. Template", Database::"Req. Wksh. Template");
        DataTransfer.AddSourceFilter(ReqWkshTemplate.FieldNo(Type), '=%1', GetOldId(20500));
        DataTransfer.AddConstantValue(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.FieldNo(Type));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
    end;

    local procedure MigrateInventoryFields()
    var
        FieldIds: List of [Integer];
    begin
        SetFieldIds(FieldIds, '20510,20511,20512,20513,20514');
        MigrateTableExtensionFields(Database::"Item Ledger Entry", FieldIds);

        SetFieldIds(FieldIds, '20510,20511,20512,20513,20514,20542');
        MigrateTableExtensionFields(Database::"Item Journal Line", FieldIds);
    end;

    local procedure MigrateManufacturingFields()
    var
        FieldIds: List of [Integer];
    begin
        SetFieldIds(FieldIds, '20500,20512,20513');
        MigrateTableExtensionFields(Database::"Capacity Ledger Entry", FieldIds);

        SetFieldIds(FieldIds, '20524,20525,20526');
        MigrateTableExtensionFields(Database::"Planning Component", FieldIds);

        SetFieldIds(FieldIds, '20522');
        MigrateTableExtensionFields(Database::"Production BOM Line", FieldIds);

        SetFieldIds(FieldIds, '20522,20523,20528');
        MigrateTableExtensionFields(Database::"Prod. Order Component", FieldIds);

        SetFieldIds(FieldIds, '20550,20560,20561,20562');
        MigrateTableExtensionFields(Database::"Prod. Order Routing Line", FieldIds);

        SetFieldIds(FieldIds, '20552');
        MigrateTableExtensionFields(Database::"Production Order", FieldIds);

        SetFieldIds(FieldIds, '20560,20561,20562');
        MigrateTableExtensionFields(Database::"Routing Line", FieldIds);
    end;

    local procedure MigratePurchaseFields()
    var
        FieldIds: List of [Integer];
    begin
        SetFieldIds(FieldIds, '20515,20517');
        MigrateTableExtensionFields(Database::Vendor, FieldIds);

        SetFieldIds(FieldIds, '20543,20544,20545,20546,20547,20548');
        MigrateTableExtensionFields(Database::"Purch. Cr. Memo Line", FieldIds);
        MigrateTableExtensionFields(Database::"Purch. Inv. Line", FieldIds);
        MigrateTableExtensionFields(Database::"Purch. Rcpt. Line", FieldIds);
        MigrateTableExtensionFields(Database::"Purchase Line Archive", FieldIds);

        SetFieldIds(FieldIds, '20520');
        MigrateTableExtensionFields(Database::"Purchase Header", FieldIds);
        MigrateTableExtensionFields(Database::"Purchase Header Archive", FieldIds);

        SetFieldIds(FieldIds, '20543,20544,20545,20546,20547,20548,20549,20560');
        MigrateTableExtensionFields(Database::"Purchase Line", FieldIds);

        SetFieldIds(FieldIds, '20516,20517,20518,20519,20520');
        MigrateTableExtensionFields(Database::"Requisition Line", FieldIds);
    end;

    local procedure MigrateSetupFields()
    var
        FieldIds: List of [Integer];
    begin
        SetFieldIds(FieldIds, '20500');
        MigrateTableExtensionFields(Database::"Application Area Setup", FieldIds);

        SetFieldIds(FieldIds, '20500,20501,20502,20504,20505,20509');
        MigrateTableExtensionFields(Database::"Manufacturing Setup", FieldIds);
    end;

    local procedure MigrateTransferFields()
    var
        FieldIds: List of [Integer];
    begin
        SetFieldIds(FieldIds, '20530,20531,20536,20537,20540,20541');
        MigrateTableExtensionFields(Database::"Direct Trans. Header", FieldIds);
        MigrateTableExtensionFields(Database::"Transfer Receipt Header", FieldIds);
        MigrateTableExtensionFields(Database::"Transfer Shipment Header", FieldIds);
        MigrateTableExtensionFields(Database::"Transfer Header", FieldIds);

        SetFieldIds(FieldIds, '20530,20531,20532,20533,20534,20535,20536,20537,20538,20539,20560');
        MigrateTableExtensionFields(Database::"Direct Trans. Line", FieldIds);
        MigrateTableExtensionFields(Database::"Transfer Receipt Line", FieldIds);
        MigrateTableExtensionFields(Database::"Transfer Shipment Line", FieldIds);

        SetFieldIds(FieldIds, '20530,20531,20532,20533,20534,20535,20536,20537,20538,20539,20560,20563');
        MigrateTableExtensionFields(Database::"Transfer Line", FieldIds);
    end;

    local procedure MigrateWarehouseFields()
    var
        FieldIds: List of [Integer];
    begin
        SetFieldIds(FieldIds, '20549,20560');
        MigrateTableExtensionFields(Database::"Posted Whse. Receipt Line", FieldIds);
        MigrateTableExtensionFields(Database::"Warehouse Receipt Line", FieldIds);

        SetFieldIds(FieldIds, '20560');
        MigrateTableExtensionFields(Database::"Posted Whse. Shipment Line", FieldIds);
        MigrateTableExtensionFields(Database::"Warehouse Shipment Line", FieldIds);
    end;

    local procedure MigrateTableData(NewTableId: Integer; FieldIds: List of [Integer])
    var
        DataTransfer: DataTransfer;
        FieldIndex: Integer;
    begin
        if not IsOldTableAvailable(NewTableId) then
            exit;
        if not AreFieldsAvailable(GetOldId(NewTableId), FieldIds) then
            exit;
        if not AreFieldsAvailable(NewTableId, FieldIds) then
            exit;

        DataTransfer.SetTables(GetOldId(NewTableId), NewTableId);
        for FieldIndex := 1 to FieldIds.Count() do
            DataTransfer.AddFieldValue(FieldIds.Get(FieldIndex), FieldIds.Get(FieldIndex));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyRows();
    end;

    local procedure MigrateTableExtensionFields(TableId: Integer; NewFieldIds: List of [Integer])
    var
        DataTransfer: DataTransfer;
        FieldIndex: Integer;
    begin
        if not AreOldFieldsAvailable(TableId, NewFieldIds) then
            exit;

        DataTransfer.SetTables(TableId, TableId);
        for FieldIndex := 1 to NewFieldIds.Count() do
            DataTransfer.AddFieldValue(GetOldId(NewFieldIds.Get(FieldIndex)), NewFieldIds.Get(FieldIndex));
        DataTransfer.UpdateAuditFields(false);
        DataTransfer.CopyFields();
    end;

    local procedure AreOldFieldsAvailable(TableId: Integer; NewFieldIds: List of [Integer]): Boolean
    var
        OldFieldIds: List of [Integer];
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to NewFieldIds.Count() do
            OldFieldIds.Add(GetOldId(NewFieldIds.Get(FieldIndex)));

        exit(AreFieldsAvailable(TableId, OldFieldIds));
    end;

    local procedure AreFieldsAvailable(TableId: Integer; FieldIds: List of [Integer]): Boolean
    var
        Field: Record Field;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to FieldIds.Count() do
            if not Field.Get(TableId, FieldIds.Get(FieldIndex)) then
                exit(false);

        exit(true);
    end;

    local procedure IsOldTableAvailable(NewTableId: Integer): Boolean
    var
        OldTableMetadata: Record "Table Metadata";
        NewTableMetadata: Record "Table Metadata";
        OldTableId: Integer;
    begin
        OldTableId := GetOldId(NewTableId);
        if not OldTableMetadata.Get(OldTableId) then
            exit(false);
        if not NewTableMetadata.Get(NewTableId) then
            exit(false);
        if (OldTableMetadata.ID <> OldTableId) or (OldTableMetadata.Caption <> NewTableMetadata.Caption) then
            exit(false);

        exit(true);
    end;

    local procedure SetFieldIds(var FieldIds: List of [Integer]; FieldIdText: Text)
    var
        FieldIdList: List of [Text];
        FieldIndex: Integer;
        FieldId: Integer;
    begin
        Clear(FieldIds);
        FieldIdList := FieldIdText.Split(',');
        for FieldIndex := 1 to FieldIdList.Count() do begin
            Evaluate(FieldId, FieldIdList.Get(FieldIndex));
            FieldIds.Add(FieldId);
        end;
    end;

    local procedure GetOldId(NewId: Integer): Integer
    begin
        exit(NewId + GetRenumberingOffset());
    end;

    local procedure GetRenumberingOffset(): Integer
    begin
        exit(98981000);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyUpgradeTag(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetRenumberedDataMigrationTag());
    end;

    local procedure GetRenumberedDataMigrationTag(): Code[250]
    begin
        exit('MS-Subcontracting-RenumberObjects-28.3-20260728');
    end;

    var
        MigrationInitiatedMsg: Label 'Subcontracting renumbering data migration was initiated.', Locked = true;
        MigrationNotInitiatedMsg: Label 'Subcontracting renumbering data migration was not initiated. Reason: %1', Locked = true;
        MigrationAlreadyCompletedLbl: Label 'The migration upgrade tag is already set.', Locked = true;
        TelemetryCategoryLbl: Label 'Subcontracting', Locked = true;
}
