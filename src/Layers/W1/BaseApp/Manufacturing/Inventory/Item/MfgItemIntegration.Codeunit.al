// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Structure;

codeunit 99000795 "Mfg. Item Integration"
{
    Permissions = tabledata "Manufacturing Setup" = r;

    var
        ChangeConfirmationQst: Label 'If you change %1 it may affect existing production orders.\Do you want to change %1?', Comment = '%1 - field caption';
        CannotDeleteDocumentErr: Label 'You cannot delete item variant %1 because there is at least one %2 that includes this Variant Code.', Comment = '%1 - item variant, %2 - document number';
        CannotDeleteProdOrderErr: Label 'You cannot delete item variant %1 because there are one or more outstanding production orders that include this item.', Comment = '%1 - variant code';
        CannotModifyUnitOfMeasureErr: Label 'You cannot modify %1 %2 for item %3 because non-zero %5 with %2 exists in %4.', Comment = '%1 Table name (Item Unit of measure), %2 Value of Measure (KG, PCS...), %3 Item ID, %4 Entry Table Name, %5 Field Caption';
        CannotRenameItemErr: Label 'You cannot rename %1 in a %2, because it is used in %3.', Comment = '%1 = Item No. caption, %2 = Table caption, %3 = Reference Table caption';

    // Item

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnValidateReplenishmentSystemCaseElse', '', false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var Item: Record Item)
    begin
        case Item."Replenishment System" of
            "Replenishment System"::"Prod. Order":
                begin
                    Item.TestField("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Stock");
                    Item.TestField(Type, Item.Type::Inventory);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure ItemOnAfterValidateEventNo(var Rec: Record Item; var xRec: Record Item)
    begin
        if (Rec."No." = xRec."No.") or (xRec."No." <> '') then
            exit;

        SetDefaultFlushingMethod(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnInsertOnAfterAssignNo', '', false, false)]
    local procedure OnInsertOnAfterAssignNo(var Item: Record Item)
    begin
        SetDefaultFlushingMethod(Item);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAssistEditOnAfterAssignNo', '', false, false)]
    local procedure OnAssistEditOnAfterAssignNo(var Item: Record Item; xItem: Record Item)
    begin
        if xItem."No." <> '' then
            exit;

        SetDefaultFlushingMethod(Item);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterHasBOM', '', false, false)]
    local procedure OnAfterHasBOM(var Item: Record Item; var Result: Boolean);
    begin
        if Item."Production BOM No." <> '' then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnIsProductionBOM', '', false, false)]
    local procedure OnIsProductionBOM(Item: Record Item; var Result: Boolean)
    begin
        Result := Item."Production BOM No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterHasRoutingNo', '', false, false)]
    local procedure OnAfterHasRoutingNo(var Item: Record Item; var Result: Boolean);
    begin
        if Item."Routing No." <> '' then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckUpdateFieldsForNonInventoriableItem', '', false, false)]
    local procedure OnAfterCheckUpdateFieldsForNonInventoriableItem(var Item: Record Item)
    begin
        Item.Validate("Production BOM No.", '');
        Item.Validate("Routing No.", '');
        Item.Validate("Overhead Rate", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnValidateGenProdPostingGroupOnConfirmChange', '', false, false)]
    local procedure OnBeforeValidateGenProdPostingGroup(var Item: Record Item; xItemGenProdPostingGroupCode: Code[20]; var ShouldExit: Boolean)
    var
        ConfirmMgt: Codeunit System.Utilities."Confirm Management";
        Question: Text;
    begin
        if ProdOrderExist(Item) then begin
            Question := StrSubstNo(ChangeConfirmationQst, Item.FieldCaption("Gen. Prod. Posting Group"));
            if not ConfirmMgt.GetResponseOrDefault(Question, true) then begin
                Item."Gen. Prod. Posting Group" := xItemGenProdPostingGroupCode;
                ShouldExit := true;
            end;
        end;
    end;

    local procedure ProdOrderExist(var Item: Record Item): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetFilter(Status, '..%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        if not ProdOrderLine.IsEmpty() then
            exit(true);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnShouldTryCostFromSKUOnCheckSKUCostOnMfg', '', false, false)]
    local procedure OnShouldTryCostFromSKUOnCheckSKUCostOnMfg(var ShouldExit: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.ReadPermission() then
            exit;

        ManufacturingSetup.Get();
        if not ManufacturingSetup."Load SKU Cost on Manufacturing" then
            ShouldExit := true;
    end;

    // Item Card

    [EventSubscriber(ObjectType::Page, Page::"Item Card", 'OnCreateItemFromTemplateOnBeforeIsFoundationEnabled', '', false, false)]
    local procedure OnCreateItemFromTemplateOnBeforeIsFoundationEnabled(var Item: Record Item)
    begin
        if Item."No." <> '' then
            exit;

        SetDefaultFlushingMethod(Item);
    end;

    // Inventory Posting Setup

    [EventSubscriber(ObjectType::Table, Database::"Inventory Posting Setup", 'OnAfterSuggestSetupAccount', '', false, false)]
    local procedure OnAfterSuggestSetupAccount(var InventoryPostingSetup: Record "Inventory Posting Setup"; RecRef: RecordRef)
    begin
        if InventoryPostingSetup."WIP Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("WIP Account"));
        if InventoryPostingSetup."Material Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Material Variance Account"));
        if InventoryPostingSetup."Capacity Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Capacity Variance Account"));
        if InventoryPostingSetup."Mfg. Overhead Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Mfg. Overhead Variance Account"));
        if InventoryPostingSetup."Cap. Overhead Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Cap. Overhead Variance Account"));
        if InventoryPostingSetup."Subcontracted Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Subcontracted Variance Account"));
    end;

    // Item Variant

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnDeleteOnAfterCheck', '', false, false)]
    local procedure ItemVariantOnDeleteOnAfterCheck(var ItemVariant: Record "Item Variant")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetCurrentKey(Type, "No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemVariant."Item No.");
        ProductionBOMLine.SetRange("Variant Code", ItemVariant.Code);
        if not ProductionBOMLine.IsEmpty() then
            Error(CannotDeleteDocumentErr, ItemVariant.Code, ProductionBOMLine.TableCaption());

        ProdOrderComponent.SetCurrentKey(Status, "Item No.");
        ProdOrderComponent.SetRange("Item No.", ItemVariant."Item No.");
        ProdOrderComponent.SetRange("Variant Code", ItemVariant.Code);
        if not ProdOrderComponent.IsEmpty() then
            Error(CannotDeleteDocumentErr, ItemVariant.Code, ProdOrderComponent.TableCaption());

        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetRange("Item No.", ItemVariant."Item No.");
        ProdOrderLine.SetRange("Variant Code", ItemVariant.Code);
        if not ProdOrderLine.IsEmpty() then
            Error(CannotDeleteProdOrderErr, ItemVariant."Item No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnBeforeRenameEvent', '', false, false)]
    local procedure OnBeforeRenameItemVariant(var Rec: Record "Item Variant"; var xRec: Record "Item Variant"; RunTrigger: Boolean)
    var
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        BinContent: Record "Bin Content";
        RequisitionLine: Record "Requisition Line";
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not RunTrigger then
            exit;

        if xRec."Item No." <> Rec."Item No." then begin
            ProdOrderLine.SetRange("Item No.", xRec."Item No.");
            ProdOrderLine.SetRange("Variant Code", xRec.Code);
            if not ProdOrderLine.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption(Rec."Item No."), Rec.TableCaption(), ProdOrderLine.TableCaption());

            BOMComponent.SetRange(Type, BOMComponent.Type::Item);
            BOMComponent.SetRange("No.", xRec."Item No.");
            BOMComponent.SetRange("Variant Code", xRec.Code);
            if not BOMComponent.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), BOMComponent.TableCaption());

            ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
            ProductionBOMLine.SetRange("No.", xRec."Item No.");
            ProductionBOMLine.SetRange("Variant Code", xRec.Code);
            if not ProductionBOMLine.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), ProductionBOMLine.TableCaption());

            ProdOrderComponent.SetRange("Item No.", xRec."Item No.");
            ProdOrderComponent.SetRange("Variant Code", xRec.Code);
            if not ProdOrderComponent.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), ProdOrderComponent.TableCaption());

            AssemblyHeader.SetRange("Item No.", xRec."Item No.");
            AssemblyHeader.SetRange("Variant Code", xRec.Code);
            if not AssemblyHeader.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), AssemblyHeader.TableCaption());

            AssemblyLine.SetRange("No.", xRec."Item No.");
            AssemblyLine.SetRange("Variant Code", xRec.Code);
            if not AssemblyLine.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), AssemblyLine.TableCaption());

            BinContent.SetRange("Item No.", xRec."Item No.");
            BinContent.SetRange("Variant Code", xRec.Code);
            if not BinContent.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), BinContent.TableCaption());

            TransferLine.SetRange("Item No.", xRec."Item No.");
            TransferLine.SetRange("Variant Code", xRec.Code);
            if not TransferLine.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), TransferLine.TableCaption());

            RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
            RequisitionLine.SetRange("No.", xRec."Item No.");
            RequisitionLine.SetRange("Variant Code", xRec.Code);
            if not RequisitionLine.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), RequisitionLine.TableCaption());

            ItemJournalLine.SetRange("Item No.", xRec."Item No.");
            ItemJournalLine.SetRange("Variant Code", xRec.Code);
            if not ItemJournalLine.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), ItemJournalLine.TableCaption());

            ItemLedgerEntry.SetRange("Item No.", xRec."Item No.");
            ItemLedgerEntry.SetRange("Variant Code", xRec.Code);
            if not ItemLedgerEntry.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), ItemLedgerEntry.TableCaption());

            ValueEntry.SetRange("Item No.", xRec."Item No.");
            ValueEntry.SetRange("Variant Code", xRec.Code);
            if not ValueEntry.IsEmpty() then
                Error(CannotRenameItemErr, Rec.FieldCaption("Item No."), Rec.TableCaption(), ValueEntry.TableCaption());
        end;
    end;

    // Item Unit of Measure

    [EventSubscriber(ObjectType::Table, Database::"Item Unit of Measure", 'OnAfterCheckNoOutstandingQty', '', false, false)]
    local procedure ItemUnitOfMeasureOnAfterCheckNoOutstandingQty(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        CheckNoRemQtyProdOrderLine(ItemUnitOfMeasure, xItemUnitOfMeasure);
        CheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure, xItemUnitOfMeasure);
    end;

    local procedure CheckNoRemQtyProdOrderLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyProdOrderLine(ItemUnitOfMeasure, xItemUnitOfMeasure, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.SetRange("Item No.", ItemUnitOfMeasure."Item No.");
        ProdOrderLine.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderLine.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderLine.SetFilter(Status, '<>%1', ProdOrderLine.Status::Finished);
        if not ProdOrderLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, ItemUnitOfMeasure.TableCaption(), xItemUnitOfMeasure.Code, ItemUnitOfMeasure."Item No.",
              ProdOrderLine.TableCaption(), ProdOrderLine.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure, xItemUnitOfMeasure, ProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComponent.SetRange("Item No.", ItemUnitOfMeasure."Item No.");
        ProdOrderComponent.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderComponent.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderComponent.SetFilter(Status, '<>%1', ProdOrderComponent.Status::Finished);
        if not ProdOrderComponent.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, ItemUnitOfMeasure.TableCaption(), xItemUnitOfMeasure.Code, ItemUnitOfMeasure."Item No.",
              ProdOrderComponent.TableCaption(), ProdOrderComponent.FieldCaption("Remaining Quantity"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyProdOrderLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    // Location

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnAfterValidateEvent', 'Use As In-Transit', false, false)]
    local procedure LocationOnAfterValidateEventUseAsInTransit(var Rec: Record Location)
    begin
        if Rec."Use As In-Transit" then begin
            Rec.TestField("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"No Warehouse Handling");
            Rec.TestField("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"No Warehouse Handling");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnAfterValidateEvent', 'Directed Put-away and Pick', false, false)]
    local procedure LocationOnAfterValidateEventDirectedPutawayandPick(var Rec: Record Location)
    begin
        if Rec."Directed Put-away and Pick" then begin
            Rec."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
            Rec."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterOnDelete(var Rec: Record Location; RunTrigger: Boolean)
    var
        WorkCenter: Record "Work Center";
    begin
        if Rec.IsTemporary() or (not RunTrigger) then
            exit;

        WorkCenter.SetRange("Location Code", Rec.Code);
        if WorkCenter.FindSet(true) then
            repeat
                WorkCenter.Validate("Location Code", '');
                WorkCenter.Modify(true);
            until WorkCenter.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnGetLocationSetupOnAfterInitLocation', '', false, false)]
    local procedure OnGetLocationSetupOnAfterInitLocation(var Location: Record Location; var Location2: Record Location)
    begin
        case true of
            not Location2."Require Pick" and not Location2."Require Shipment",
            not Location2."Require Pick" and Location2."Require Shipment":
                Location2."Prod. Consump. Whse. Handling" := Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location2."Require Pick" and not Location2."Require Shipment":
                Location2."Prod. Consump. Whse. Handling" := Enum::"Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
            Location2."Require Pick" and Location2."Require Shipment":
                Location2."Prod. Consump. Whse. Handling" := Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        end;

        case true of
            not Location2."Require Put-away" and not Location2."Require Receive",
            not Location2."Require Put-away" and Location2."Require Receive",
            Location2."Require Put-away" and Location2."Require Receive":
                Location2."Prod. Output Whse. Handling" := Enum::"Prod. Output Whse. Handling"::"No Warehouse Handling";
            Location2."Require Put-away" and not Location2."Require Receive":
                Location2."Prod. Output Whse. Handling" := Enum::"Prod. Output Whse. Handling"::"Inventory Put-away";
        end;
    end;

    // Stockkeeping Unit

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnAfterValidateEvent', 'Variant Code', false, false)]
    local procedure LocationOnAfterValidateEventVariantCode(var Rec: Record "Stockkeeping Unit")
    begin
        Rec.CalcFields("Qty. on Prod. Order", "Qty. on Component Lines");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnAfterValidateEvent', 'Location Code', false, false)]
    local procedure LocationOnAfterValidateEventLocationCode(var Rec: Record "Stockkeeping Unit")
    begin
        Rec.CalcFields("Qty. on Prod. Order", "Qty. on Component Lines");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnAfterValidateEvent', "Item No.", false, false)]
    local procedure OnAfterValidateEventItemNo(var Rec: Record "Stockkeeping Unit"; var xRec: Record "Stockkeeping Unit")
    var
        Item: Record Item;
    begin
        if Rec."Item No." <> xRec."Item No." then
            if Item.Get(Rec."Item No.") then
                Rec.TransferManufCostsFromItem(Item);
    end;

    // Catalog Item Management

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Catalog Item Management", 'OnCreateNewItemOnBeforeItemInsert', '', false, false)]
    local procedure OnCreateNewItemOnBeforeItemInsert(var Item: Record Item; NonstockItem: Record "Nonstock Item")
    begin
        SetDefaultFlushingMethod(Item);
    end;

    // Item Templ. Mgt.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", 'OnCreateItemFromTemplateOnBeforeItemInsert', '', false, false)]
    local procedure OnCreateItemFromTemplateOnBeforeItemInsert(var Item: Record Item)
    begin
        SetDefaultFlushingMethod(Item);
    end;

    // Item Templ. Card

    [EventSubscriber(ObjectType::Page, Page::"Item Templ. Card", 'OnAfterOnNewRecord', '', false, false)]
    local procedure OnAfterOnNewRecord(var ItemTempl: Record "Item Templ.")
    begin
        SetDefaultFlushingMethod(ItemTempl);
    end;

    local procedure SetDefaultFlushingMethod(var Item: Record Item)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.ReadPermission() then
            exit;

        if ManufacturingSetup.Get() then
            Item."Flushing Method" := ManufacturingSetup."Default Flushing Method";
    end;

    local procedure SetDefaultFlushingMethod(var ItemTempl: Record "Item Templ.")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.ReadPermission() then
            exit;

        if ManufacturingSetup.Get() then
            ItemTempl."Flushing Method" := ManufacturingSetup."Default Flushing Method";
    end;
}
