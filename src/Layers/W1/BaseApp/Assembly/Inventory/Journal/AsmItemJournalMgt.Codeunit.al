// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Assembly.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Setup;

codeunit 924 "Asm. Item Journal Mgt."
{
    var
        CannotChangeFieldErr: Label 'You cannot change %1 when %2 is %3.', Comment = '%1 %2 - field captions, %3 - field value';

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnIsAssemblyItem', '', false, false)]
    local procedure OnIsAssemblyItem(Item: Record Item; var Result: Boolean)
    begin
        Result := Item."Replenishment System" = Item."Replenishment System"::Assembly;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnValidateItemNoOnSetCostAndPrice', '', false, false)]
    local procedure OnValidateItemNoOnSetCostAndPrice(var ItemJournalLine: Record "Item Journal Line"; UnitCost: Decimal)
    begin
        case ItemJournalLine."Entry Type" of
            ItemJournalLine."Entry Type"::"Assembly Output":
                ItemJournalLine.ApplyPrice("Price Type"::Purchase, ItemJournalLine.FieldNo("Item No."));
            ItemJournalLine."Entry Type"::"Assembly Consumption":
                ItemJournalLine."Unit Amount" := UnitCost;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnValidateUnitAmountOnUpdateByEntryType', '', false, false)]
    local procedure OnValidateUnitAmountOnUpdateByEntryType(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    var
        Item: Record Item;
        GLSetup: Record "General Ledger Setup";
    begin
        case ItemJournalLine."Entry Type" of
            ItemJournalLine."Entry Type"::"Assembly Output":
                begin
                    GLSetup.Get();
                    if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Purchase then
                        ItemJournalLine."Unit Cost" := ItemJournalLine."Unit Amount";
                    if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Positive Adjmt." then
                        ItemJournalLine."Unit Cost" :=
                            Round(
                            ItemJournalLine."Unit Amount" * (1 + ItemJournalLine."Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                            ItemJournalLine."Overhead Rate" * ItemJournalLine."Qty. per Unit of Measure";
                    if (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::"Direct Cost") and
                        (ItemJournalLine."Item Charge No." = '')
                    then
                        ItemJournalLine.Validate("Unit Cost");
                end;
            ItemJournalLine."Entry Type"::"Assembly Consumption":
                begin
                    Item.Get(ItemJournalLine."Item No.");
                    if (CurrentFieldNo = ItemJournalLine.FieldNo("Unit Amount")) and
                        (Item."Costing Method" = Item."Costing Method"::Standard)
                    then
                        Error(
                            CannotChangeFieldErr,
                            ItemJournalLine.FieldCaption("Unit Amount"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    ItemJournalLine."Unit Cost" := ItemJournalLine."Unit Amount";
                    if (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::"Direct Cost") and
                        (ItemJournalLine."Item Charge No." = '')
                    then
                        ItemJournalLine.Validate("Unit Cost");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnValidateUnitCostOnUpdateByEntryType', '', false, false)]
    local procedure OnValidateUnitCostOnUpdateByEntryType(var ItemJournalLine: Record "Item Journal Line"; CurrentFieldNo: Integer)
    var
        Item: Record Item;
        GLSetup: Record "General Ledger Setup";
    begin
        case ItemJournalLine."Entry Type" of
            ItemJournalLine."Entry Type"::"Assembly Output":
                begin
                    GLSetup.Get();
                    ItemJournalLine."Unit Amount" :=
                        Round(
                        (ItemJournalLine."Unit Cost" - ItemJournalLine."Overhead Rate" * ItemJournalLine."Qty. per Unit of Measure") / (1 + ItemJournalLine."Indirect Cost %" / 100),
                        GLSetup."Unit-Amount Rounding Precision")
                end;
            ItemJournalLine."Entry Type"::"Assembly Consumption":
                begin
                    Item.Get(ItemJournalLine."Item No.");
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        Error(
                            CannotChangeFieldErr,
                            ItemJournalLine.FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    ItemJournalLine."Unit Amount" := ItemJournalLine."Unit Cost";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnValidateEntryTypeOnUpdateByEntryType', '', false, false)]
    local procedure OnValidateEntryTypeOnUpdateByEntryType(var ItemJournalLine: Record "Item Journal Line")
    begin
        case ItemJournalLine."Entry Type" of
            ItemJournalLine."Entry Type"::"Assembly Consumption", ItemJournalLine."Entry Type"::"Assembly Output":
                ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Assembly);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnValidateOrderNoOnCaseOrderTypeElse', '', false, false)]
    local procedure OnValidateOrderNoOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        case ItemJournalLine."Order Type" of
            ItemJournalLine."Order Type"::Assembly:
                begin
                    if ItemJournalLine."Order No." = '' then begin
                        ItemJournalLine.CreateAssemblyDim();
                        exit;
                    end;

                    AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, ItemJournalLine."Order No.");
                    ItemJournalLine.Description := AssemblyHeader.Description;
                    OnValidateOrderNoOnAfterCopyFromAssemblyHeader(ItemJournalLine, AssemblyHeader);

                    case true of
                        ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Assembly Output":
                            begin
                                ItemJournalLine."Inventory Posting Group" := AssemblyHeader."Inventory Posting Group";
                                ItemJournalLine."Gen. Prod. Posting Group" := AssemblyHeader."Gen. Prod. Posting Group";
                            end;
                    end;

                    if (ItemJournalLine."Order No." <> xItemJournalLine."Order No.") or (ItemJournalLine."Order Type" <> xItemJournalLine."Order Type") then
                        ItemJournalLine.CreateAssemblyDim();
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOnAfterCopyFromAssemblyHeader(var ItemJournalLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnValidateOrderLineNoOnCaseOrderTypeElse', '', false, false)]
    local procedure OnValidateOrderLineNoOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line"; var xItemJournalLine: Record "Item Journal Line")
    begin
        case ItemJournalLine."Order Type" of
            ItemJournalLine."Order Type"::Assembly:
                if ItemJournalLine."Order Line No." <> xItemJournalLine."Order Line No." then
                    ItemJournalLine.CreateAssemblyDim();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterSigned', '', false, false)]
    local procedure OnAfterSigned(ItemJournalLine: Record "Item Journal Line"; Value: Decimal; var Result: Decimal)
    begin
        case ItemJournalLine."Entry Type" of
            ItemJournalLine."Entry Type"::"Assembly Output":
                Result := Value;
            ItemJournalLine."Entry Type"::"Assembly Consumption":
                Result := -Value;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterSetDefaultPriceCalculationMethod', '', false, false)]
    local procedure OnAfterSetDefaultPriceCalculationMethod(var ItemJournalLine: Record "Item Journal Line")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        case ItemJournalLine."Entry Type" of
            ItemJournalLine."Entry Type"::"Assembly Output":
                begin
                    PurchasesPayablesSetup.Get();
                    ItemJournalLine."Price Calculation Method" := PurchasesPayablesSetup."Price Calculation Method";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckEntryType', '', false, false)]
    local procedure OnAfterCheckEntryType(var ItemJournalLine: Record "Item Journal Line")
    begin
        if ItemJournalLine.Type = ItemJournalLine.Type::Resource then
            ItemJournalLine.TestField("Entry Type", ItemJournalLine."Entry Type"::"Assembly Output")
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterIsEntryTypeConsumption', '', false, false)]
    local procedure OnAfterIsEntryTypeConsumption(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Assembly Consumption" then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterIsOrderTypeAsmOrProd', '', false, false)]
    local procedure OnAfterIsOrderTypeAsmOrProd(var ItemJournalLine: Record "Item Journal Line"; var Result: Boolean)
    begin
        if ItemJournalLine."Order Type" = ItemJournalLine."Order Type"::Assembly then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse', '', false, false)]
    local procedure OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse(var ItemJournalLine: Record "Item Journal Line")
    var
        CostCalculationManagement: Codeunit "Cost Calculation Management";
    begin
        case ItemJournalLine."Order Type" of
            ItemJournalLine."Order Type"::Assembly:
                CostCalculationManagement.ResourceCostPerUnit(
                    ItemJournalLine."No.", ItemJournalLine."Unit Amount", ItemJournalLine."Indirect Cost %", ItemJournalLine."Overhead Rate", ItemJournalLine."Unit Cost");
        end;
    end;
}