// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN26
namespace System.Environment.Configuration;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 5892 "Feature-ManualFlushingMethod" implements "Feature Data Update"
{
    Access = Internal;
    Permissions = TableData "Feature Data Update Status" = rm;
    ObsoleteReason = 'Feature ''Manual Flushing Method without requiring pick'' will be enabled by default in version 29.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    // The Data upgrade codeunit for ''Manual Flushing Method without requiring pick'' feature. Moves 'Manual' to 'Pick + Manual' Flushing Method.
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        DescriptionTxt: Label 'If you enable Manufacturing %1 %2 without requiring pick, existing records from %3 tables will be updated from %1 to %4 %2.\Please be aware that the update process may take some time, depending on the volume of records.\It is advised to perform the update outside of working hours and ensure that no other users are changing data during this time.', Comment = '%1 = Manual option caption, %2 = Flushing Method caption, %3 = List of table captions, %4 = Pick + Manual option caption';
        TableCaptionsTxt: Label '%1, %2, %3, %4, %5 and %6', Comment = '%1 = Item, %2 = Item Templ., %3 = Stockkeeping Unit, %4 = Prod. Order Component, %5 = Planning Component, %6 = Manufacturing Setup';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        // Data upgrade is not required if there are no records in Production Order table.
        if CheckProductionOrderIsEmpty() then begin
            SetUpgradeTag(false);
            exit(false);
        end;

        // Data upgrade is not required if CountRecords() returns 0 records.
        CountRecords();
        if TempDocumentEntry.IsEmpty() then begin
            SetUpgradeTag(false);
            exit(false);
        end;

        exit(true);
    end;

    procedure ReviewData()
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProdOrderComponent: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ManufacturingSetup: Record "Manufacturing Setup";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        UpdateFromManualToPickPlusManualFlushingMethod_Item();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, Item.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        UpdateFromManualToPickPlusManualFlushingMethod_ItemTemplate();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ItemTempl.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        UpdateFromManualToPickPlusManualFlushingMethod_StockkeepingUnit();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, StockkeepingUnit.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        UpdateFromManualToPickPlusManualFlushingMethod_ProdOrderComponent();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ProdOrderComponent.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        UpdateFromManualToPickPlusManualFlushingMethod_PlanningComponent();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PlanningComponent.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        UpdateFromManualToPickPlusManualFlushingMethod_ManufacturingSetup();
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ManufacturingSetup.TableCaption(), StartDateTime);
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        UpdateFeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        UpdateFeatureDataUpdateStatus.SetRange("Feature Key", FeatureDataUpdateStatus."Feature Key");
        UpdateFeatureDataUpdateStatus.SetFilter("Company Name", '<>%1', FeatureDataUpdateStatus."Company Name");
        UpdateFeatureDataUpdateStatus.ModifyAll("Feature Status", FeatureDataUpdateStatus."Feature Status");  // Data is not per company

        SetUpgradeTag(true);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    var
        Item: Record Item;
    begin
        TaskDescription := StrSubstNo(DescriptionTxt,
                            Item."Flushing Method"::Manual, Item.FieldCaption("Flushing Method"), GetListOfTablesToUpdate(), Item."Flushing Method"::"Pick + Manual");
    end;

    local procedure CheckProductionOrderIsEmpty(): Boolean;
    var
        ProductionOrder: Record "Production Order";
    begin
        exit(ProductionOrder.IsEmpty());
    end;

    local procedure CountRecords(): Integer
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProdOrderComponent: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        Item.SetRange("Flushing Method", Item."Flushing Method"::Manual);
        InsertDocumentEntry(Database::"Item", Item.TableCaption(), Item.Count());

        ItemTempl.SetRange("Flushing Method", ItemTempl."Flushing Method"::Manual);
        InsertDocumentEntry(Database::"Item Templ.", ItemTempl.TableCaption(), ItemTempl.Count());

        StockkeepingUnit.SetRange("Flushing Method", StockkeepingUnit."Flushing Method"::Manual);
        InsertDocumentEntry(Database::"Stockkeeping Unit", StockkeepingUnit.TableCaption(), StockkeepingUnit.Count());

        ProdOrderComponent.SetRange("Flushing Method", ProdOrderComponent."Flushing Method"::Manual);
        InsertDocumentEntry(Database::"Prod. Order Component", ProdOrderComponent.TableCaption(), ProdOrderComponent.Count());

        PlanningComponent.SetRange("Flushing Method", PlanningComponent."Flushing Method"::Manual);
        InsertDocumentEntry(Database::"Planning Component", PlanningComponent.TableCaption(), PlanningComponent.Count());

        ManufacturingSetup.SetRange("Default Flushing Method", ManufacturingSetup."Default Flushing Method"::Manual);
        InsertDocumentEntry(Database::"Manufacturing Setup", ManufacturingSetup.TableCaption(), ManufacturingSetup.Count());
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_Item()
    var
        Item: Record Item;
        ItemToUpdate: Record Item;
    begin
        Item.SetRange("Flushing Method", Item."Flushing Method"::Manual);
        if Item.FindSet(true) then
            repeat
                ItemToUpdate.Copy(Item);
                ItemToUpdate."Flushing Method" := ItemToUpdate."Flushing Method"::"Pick + Manual";
                ItemToUpdate.Modify();
            until Item.Next() = 0;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_ItemTemplate()
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplToUpdate: Record "Item Templ.";
    begin
        ItemTempl.SetRange("Flushing Method", ItemTempl."Flushing Method"::Manual);
        if ItemTempl.FindSet(true) then
            repeat
                ItemTemplToUpdate.Copy(ItemTempl);
                ItemTemplToUpdate."Flushing Method" := ItemTemplToUpdate."Flushing Method"::"Pick + Manual";
                ItemTemplToUpdate.Modify();
            until ItemTempl.Next() = 0;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_StockkeepingUnit()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnitToUpdate: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.SetRange("Flushing Method", StockkeepingUnit."Flushing Method"::Manual);
        if StockkeepingUnit.FindSet(true) then
            repeat
                StockkeepingUnitToUpdate.Copy(StockkeepingUnit);
                StockkeepingUnitToUpdate."Flushing Method" := StockkeepingUnitToUpdate."Flushing Method"::"Pick + Manual";
                StockkeepingUnitToUpdate.Modify();
            until StockkeepingUnit.Next() = 0;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_ProdOrderComponent()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderComponentToUpdate: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Flushing Method", ProdOrderComponent."Flushing Method"::Manual);
        if ProdOrderComponent.FindSet(true) then
            repeat
                ProdOrderComponentToUpdate.Copy(ProdOrderComponent);
                ProdOrderComponentToUpdate."Flushing Method" := ProdOrderComponentToUpdate."Flushing Method"::"Pick + Manual";
                ProdOrderComponentToUpdate.Modify();
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_PlanningComponent()
    var
        PlanningComponent: Record "Planning Component";
        PlanningComponentToUpdate: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Flushing Method", PlanningComponent."Flushing Method"::Manual);
        if PlanningComponent.FindSet(true) then
            repeat
                PlanningComponentToUpdate.Copy(PlanningComponent);
                PlanningComponentToUpdate."Flushing Method" := PlanningComponentToUpdate."Flushing Method"::"Pick + Manual";
                PlanningComponentToUpdate.Modify();
            until PlanningComponent.Next() = 0;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_ManufacturingSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.SetRange("Default Flushing Method", ManufacturingSetup."Default Flushing Method"::Manual);
        if ManufacturingSetup.FindSet(true) then
            repeat
                ManufacturingSetup."Default Flushing Method" := ManufacturingSetup."Default Flushing Method"::"Pick + Manual";
                ManufacturingSetup.Modify();
            until ManufacturingSetup.Next() = 0;
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

    local procedure GetListOfTablesToUpdate() Result: Text;
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProdOrderComponent: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        Result := StrSubstNo(
                    TableCaptionsTxt,
                    Item.TableCaption(), ItemTempl.TableCaption(), StockkeepingUnit.TableCaption(),
                    ProdOrderComponent.TableCaption(), PlanningComponent.TableCaption(),
                    ManufacturingSetup.TableCaption());
    end;

    local procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        // Set the upgrade tag to indicate that the data update is executed/skipped and the feature is enabled.
        // This is needed when the feature is enabled by default in a future version, to skip the data upgrade.
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag()) then
            exit;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag());
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(UpgradeTagDefinitions.GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag(), true);
    end;
}
#endif
