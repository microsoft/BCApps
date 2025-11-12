// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;

codeunit 99000887 "Planning Comp. Avail. Mgt."
{
    // Codeunit "Item Availability Forms Mgt"

    procedure ShowItemAvailabilityFromPlanningComp(var PlanningComp: Record "Planning Component"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        ForecastName: Code[10];
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        PlanningComp.TestField("Item No.");
        Item.Reset();
        Item.Get(PlanningComp."Item No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, PlanningComp."Location Code", PlanningComp."Variant Code", PlanningComp."Due Date");

        OnBeforeShowItemAvailFromPlanningComp(Item, PlanningComp);
#if not CLEAN25
        ItemAvailabilityFormsMgt.RunOnBeforeShowItemAvailFromPlanningComp(Item, PlanningComp);
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, PlanningComp.FieldCaption(PlanningComp."Due Date"), PlanningComp."Due Date", NewDate) then
                    PlanningComp.Validate(PlanningComp."Due Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, PlanningComp.FieldCaption(PlanningComp."Variant Code"), PlanningComp."Variant Code", NewVariantCode) then
                    PlanningComp.Validate(PlanningComp."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, PlanningComp.FieldCaption(PlanningComp."Location Code"), PlanningComp."Location Code", NewLocationCode) then
                    PlanningComp.Validate(PlanningComp."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                begin
                    ForecastName := '';
                    PlanningComp.FindCurrForecastName(ForecastName);
                    ItemAvailabilityFormsMgt.SetForecastName(ForecastName);
                    if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, PlanningComp.FieldCaption(PlanningComp."Due Date"), PlanningComp."Due Date", NewDate, true) then
                        PlanningComp.Validate(PlanningComp."Due Date", NewDate);
                end;
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, PlanningComp.FieldCaption(PlanningComp."Due Date"), PlanningComp."Due Date", NewDate) then
                    PlanningComp.Validate(PlanningComp."Due Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, PlanningComp.FieldCaption(PlanningComp."Unit of Measure Code"), PlanningComp."Unit of Measure Code", NewUnitOfMeasureCode) then
                    PlanningComp.Validate(PlanningComp."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromPlanningComp(var Item: Record Item; var PlanningComp: Record "Planning Component")
    begin
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        PlanningComponent: Record "Planning Component";
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Planning Component", Item.FieldNo("Planning Issues (Qty.)"),
                    PlanningComponent.TableCaption(), Item."Planning Issues (Qty.)", QtyByUnitOfMeasure, Sign);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        PlanningComponent: Record "Planning Component";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Planning Component":
                begin
                    PlanningComponent.FindLinesWithItemToPlan(Item);
                    PAGE.RunModal(0, PlanningComponent);
                end;
        end;
    end;
}
