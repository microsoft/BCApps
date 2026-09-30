// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

#if not CLEANSCHEMA29
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
#endif

codeunit 104062 "Mfg. Upgrade BaseApp"
{
    Subtype = Upgrade;

    var
        HybridDeployment: Codeunit System.Environment."Hybrid Deployment";
#if not CLEANSCHEMA29
        UpgradeTag: Codeunit System.Upgrade."Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
#endif

    trigger OnUpgradePerCompany()
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;


#if not CLEANSCHEMA29
        UpgradeFlushingMethod();
#endif


        UpgradeProdDefinitionDisplaySetup();
    end;

#if not CLEANSCHEMA29
    local procedure UpgradeFlushingMethod()
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag()) then
            exit;

        // Data upgrade is not required if there are no records in Production Order table.
        if CheckProductionOrderIsEmpty() then begin
            SetUpgradeTag(false, UpgradeTagDefinitions.GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag());
            exit;
        end;

        // Data upgrade is not required if there are no records to update
        if not CheckRecordsToUpdateExist() then begin
            SetUpgradeTag(false, UpgradeTagDefinitions.GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag());
            exit;
        end;

        UpdateFromManualToPickPlusManualFlushingMethod_Item();
        UpdateFromManualToPickPlusManualFlushingMethod_ItemTemplate();
        UpdateFromManualToPickPlusManualFlushingMethod_StockkeepingUnit();
        UpdateFromManualToPickPlusManualFlushingMethod_ProdOrderComponent();
        UpdateFromManualToPickPlusManualFlushingMethod_PlanningComponent();
        UpdateFromManualToPickPlusManualFlushingMethod_ManufacturingSetup();

        SetUpgradeTag(true, UpgradeTagDefinitions.GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag());
    end;
#endif

    local procedure UpgradeProdDefinitionDisplaySetup()
    var
        ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
        UpgradeTagLocal: Codeunit System.Upgrade."Upgrade Tag";
        UpgradeTagDefinitionsLocal: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTagLocal.HasUpgradeTag(UpgradeTagDefinitionsLocal.GetProdDefinitionDisplaySetupUpgradeTag()) then
            exit;

        // The "Show Rtng BOM Select ..." and "Show Prod Comp Select ..." fields on Manufacturing Setup were added with
        // InitValue = Edit, but InitValue only applies to new records. Back-fill the fields to Edit to match the intended 
        // default.
        if ManufacturingSetup.Get() then begin
            ManufacturingSetup."Show Rtng BOM Select Both" := ManufacturingSetup."Show Rtng BOM Select Both"::Edit;
            ManufacturingSetup."Show Rtng BOM Select Partial" := ManufacturingSetup."Show Rtng BOM Select Partial"::Edit;
            ManufacturingSetup."Show Rtng BOM Select Nothing" := ManufacturingSetup."Show Rtng BOM Select Nothing"::Edit;
            ManufacturingSetup."Show Prod Comp Select Both" := ManufacturingSetup."Show Prod Comp Select Both"::Edit;
            ManufacturingSetup."Show Prod Comp Select Partial" := ManufacturingSetup."Show Prod Comp Select Partial"::Edit;
            ManufacturingSetup."Show Prod Comp Select Nothing" := ManufacturingSetup."Show Prod Comp Select Nothing"::Edit;
            ManufacturingSetup.Modify();
        end;

        UpgradeTagLocal.SetUpgradeTag(UpgradeTagDefinitionsLocal.GetProdDefinitionDisplaySetupUpgradeTag());
    end;

#if not CLEANSCHEMA29
    local procedure CheckProductionOrderIsEmpty(): Boolean;
    var
        ProductionOrder: Record "Production Order";
    begin
        exit(ProductionOrder.IsEmpty());
    end;

    local procedure CheckRecordsToUpdateExist(): Boolean
    var
        Item: Record Item;
        ItemTempl: Record "Item Templ.";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProdOrderComponent: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        Item.SetRange("Flushing Method", Item."Flushing Method"::Manual);
        if not Item.IsEmpty() then
            exit(true);

        ItemTempl.SetRange("Flushing Method", ItemTempl."Flushing Method"::Manual);
        if not ItemTempl.IsEmpty() then
            exit(true);

        StockkeepingUnit.SetRange("Flushing Method", StockkeepingUnit."Flushing Method"::Manual);
        if not StockkeepingUnit.IsEmpty() then
            exit(true);

        ProdOrderComponent.SetRange("Flushing Method", ProdOrderComponent."Flushing Method"::Manual);
        if not ProdOrderComponent.IsEmpty() then
            exit(true);

        PlanningComponent.SetRange("Flushing Method", PlanningComponent."Flushing Method"::Manual);
        if not PlanningComponent.IsEmpty() then
            exit(true);

        ManufacturingSetup.SetRange("Default Flushing Method", ManufacturingSetup."Default Flushing Method"::Manual);
        if not ManufacturingSetup.IsEmpty() then
            exit(true);
    end;
#endif

#if not CLEANSCHEMA29
    local procedure SetUpgradeTag(DataUpgradeExecuted: Boolean; UpgradeTagCode: Code[250])
    begin
        UpgradeTag.SetUpgradeTag(UpgradeTagCode);
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(UpgradeTagCode, true);
    end;
#endif

#if not CLEANSCHEMA29
    local procedure UpdateFromManualToPickPlusManualFlushingMethod_Item()
    var
        Item: Record Item;
        ItemDataTransfer: DataTransfer;
    begin
        Item.SetRange("Flushing Method", Item."Flushing Method"::Manual);
        if not Item.IsEmpty() then begin
            ItemDataTransfer.SetTables(Database::"Item", Database::"Item");
            ItemDataTransfer.AddSourceFilter(Item.FieldNo("Flushing Method"), '=%1', Item."Flushing Method"::Manual);
            ItemDataTransfer.AddConstantValue(Item."Flushing Method"::"Pick + Manual", Item.FieldNo("Flushing Method"));
            ItemDataTransfer.UpdateAuditFields := false;
            ItemDataTransfer.CopyFields();
        end;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_ItemTemplate()
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplDataTransfer: DataTransfer;
    begin
        ItemTempl.SetRange("Flushing Method", ItemTempl."Flushing Method"::Manual);
        if not ItemTempl.IsEmpty() then begin
            ItemTemplDataTransfer.SetTables(Database::"Item Templ.", Database::"Item Templ.");
            ItemTemplDataTransfer.AddSourceFilter(ItemTempl.FieldNo("Flushing Method"), '=%1', ItemTempl."Flushing Method"::Manual);
            ItemTemplDataTransfer.AddConstantValue(ItemTempl."Flushing Method"::"Pick + Manual", ItemTempl.FieldNo("Flushing Method"));
            ItemTemplDataTransfer.UpdateAuditFields := false;
            ItemTemplDataTransfer.CopyFields();
        end;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_StockkeepingUnit()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnitDataTransfer: DataTransfer;
    begin
        StockkeepingUnit.SetRange("Flushing Method", StockkeepingUnit."Flushing Method"::Manual);
        if not StockkeepingUnit.IsEmpty() then begin
            StockkeepingUnitDataTransfer.SetTables(Database::"Stockkeeping Unit", Database::"Stockkeeping Unit");
            StockkeepingUnitDataTransfer.AddSourceFilter(StockkeepingUnit.FieldNo("Flushing Method"), '=%1', StockkeepingUnit."Flushing Method"::Manual);
            StockkeepingUnitDataTransfer.AddConstantValue(StockkeepingUnit."Flushing Method"::"Pick + Manual", StockkeepingUnit.FieldNo("Flushing Method"));
            StockkeepingUnitDataTransfer.UpdateAuditFields := false;
            StockkeepingUnitDataTransfer.CopyFields();
        end;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_ProdOrderComponent()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderComponentDataTransfer: DataTransfer;
    begin
        ProdOrderComponent.SetRange("Flushing Method", ProdOrderComponent."Flushing Method"::Manual);
        if not ProdOrderComponent.IsEmpty() then begin
            ProdOrderComponentDataTransfer.SetTables(Database::"Prod. Order Component", Database::"Prod. Order Component");
            ProdOrderComponentDataTransfer.AddSourceFilter(ProdOrderComponent.FieldNo("Flushing Method"), '=%1', ProdOrderComponent."Flushing Method"::Manual);
            ProdOrderComponentDataTransfer.AddConstantValue(ProdOrderComponent."Flushing Method"::"Pick + Manual", ProdOrderComponent.FieldNo("Flushing Method"));
            ProdOrderComponentDataTransfer.UpdateAuditFields := false;
            ProdOrderComponentDataTransfer.CopyFields();
        end;
    end;

    local procedure UpdateFromManualToPickPlusManualFlushingMethod_PlanningComponent()
    var
        PlanningComponent: Record "Planning Component";
        PlanningComponentDataTransfer: DataTransfer;
    begin
        PlanningComponent.SetRange("Flushing Method", PlanningComponent."Flushing Method"::Manual);
        if not PlanningComponent.IsEmpty() then begin
            PlanningComponentDataTransfer.SetTables(Database::"Planning Component", Database::"Planning Component");
            PlanningComponentDataTransfer.AddSourceFilter(PlanningComponent.FieldNo("Flushing Method"), '=%1', PlanningComponent."Flushing Method"::Manual);
            PlanningComponentDataTransfer.AddConstantValue(PlanningComponent."Flushing Method"::"Pick + Manual", PlanningComponent.FieldNo("Flushing Method"));
            PlanningComponentDataTransfer.UpdateAuditFields := false;
            PlanningComponentDataTransfer.CopyFields();
        end;
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
#endif


}