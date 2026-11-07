// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.UOM;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

codeunit 5402 "Unit of Measure Management"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        QtyPerUnitOfMeasureErr: Label 'Quantity per unit of measure must be defined.';
        QuantityImbalanceErr: Label '%1 on %2-%3 causes the %4 and %5 to be out of balance. Rounding of the field %5 results to 0.', Comment = '%1 - field name, %2 - table name, %3 - primary key value, %4 - field name, %5 - field name';
        InvalidPrecisionErr: Label 'The value %1 in field %2 is of lower precision than expected. \\Note: Default rounding precision of %3 is used if a rounding precision is not defined.', Comment = '%1 - decimal value, %2 - field name, %3 - default rounding precision.';
        QtyImbalanceDetectedErr: Label 'This will cause the quantity and base quantity fields to be out of balance.';

    procedure GetQtyPerUnitOfMeasure(Item: Record Item; UnitOfMeasureCode: Code[10]) QtyPerUnitOfMeasure: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetQtyPerUnitOfMeasure(Item, UnitOfMeasureCode, QtyPerUnitOfMeasure, IsHandled);
        if IsHandled then
            exit(QtyPerUnitOfMeasure);

        Item.TestField("No.");
        if UnitOfMeasureCode in [Item."Base Unit of Measure", ''] then
            exit(1);
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           (UnitOfMeasureCode <> ItemUnitOfMeasure.Code)
        then
            ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasureCode);
        ItemUnitOfMeasure.TestField("Qty. per Unit of Measure");
        exit(ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    procedure GetQtyRoundingPrecision(Item: Record Item; UnitOfMeasureCode: Code[10]) QtyRoundingPrecision: Decimal
    begin
        Item.TestField("No.");
        if UnitOfMeasureCode = '' then
            exit(0);
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           (UnitOfMeasureCode <> ItemUnitOfMeasure.Code)
        then
            ItemUnitOfMeasure.Get(Item."No.", UnitOfMeasureCode);
        exit(ItemUnitOfMeasure."Qty. Rounding Precision");
    end;

    procedure GetResQtyPerUnitOfMeasure(Resource: Record Resource; UnitOfMeasureCode: Code[10]) QtyPerUnitOfMeasure: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetResQtyPerUnitOfMeasure(Resource, UnitOfMeasureCode, QtyPerUnitOfMeasure, IsHandled);
        if IsHandled then
            exit(QtyPerUnitOfMeasure);

        Resource.TestField("No.");
        if UnitOfMeasureCode in [Resource."Base Unit of Measure", ''] then
            exit(1);
        if (Resource."No." <> ResourceUnitOfMeasure."Resource No.") or
           (UnitOfMeasureCode <> ResourceUnitOfMeasure.Code)
        then
            ResourceUnitOfMeasure.Get(Resource."No.", UnitOfMeasureCode);
        ResourceUnitOfMeasure.TestField("Qty. per Unit of Measure");
        exit(ResourceUnitOfMeasure."Qty. per Unit of Measure");
    end;

    procedure CalcBaseQty(Qty: Decimal; QtyPerUOM: Decimal): Decimal
    begin
        exit(CalcBaseQty('', '', '', Qty, QtyPerUOM));
    end;

    procedure CalcBaseQty(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal) QtyRounded: Decimal
    begin
        QtyRounded := CalcBaseQty(ItemNo, VariantCode, UOMCode, QtyBase, QtyPerUOM, 0);
    end;

    procedure CalcBaseQty(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; QtyRndingPrecision: Decimal) QtyRounded: Decimal
    begin
        QtyRounded := CalcBaseQty(ItemNo, VariantCode, UOMCode, QtyBase, QtyPerUOM, QtyRndingPrecision, '', '', '');
    end;

    procedure CalcBaseQty(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; QtyRndingPrecision: Decimal; BasedOnField: Text; FromFieldName: Text; ToFieldName: Text) QtyRounded: Decimal
    var
        DummyItem: Record Item;
    begin
        QtyRounded := 0;
        if QtyPerUOM <> 0 then begin
            QtyRounded := RoundQty(QtyBase * QtyPerUOM, QtyRndingPrecision);

            if (QtyRounded = 0) and (QtyBase <> 0) then
                Error(QuantityImbalanceErr, BasedOnField, DummyItem.TableCaption(), ItemNo, FromFieldName, ToFieldName);
        end;
        OnAfterCalcBaseQtyPerUnitOfMeasure(ItemNo, VariantCode, UOMCode, QtyBase, QtyPerUOM, QtyRounded);
    end;

    procedure CalcQtyFromBase(QtyBase: Decimal; QtyPerUOM: Decimal): Decimal
    begin
        exit(CalcQtyFromBase('', '', '', QtyBase, QtyPerUOM));
    end;

    procedure CalcQtyFromBase(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal) QtyRounded: Decimal
    begin
        if QtyPerUOM = 0 then
            Error(QtyPerUnitOfMeasureErr);

        QtyRounded := RoundQty(QtyBase / QtyPerUOM);

        OnAfterCalcQtyFromBasePerUnitOfMeasure(ItemNo, VariantCode, UOMCode, QtyBase, QtyPerUOM, QtyRounded);
    end;

    procedure RoundQty(Qty: Decimal): Decimal
    begin
        exit(Round(Qty, QtyRndPrecision()));
    end;

    procedure RoundQty(Qty: Decimal; QtyRndingPrecision: Decimal): Decimal
    begin
        exit(RoundQty(Qty, QtyRndingPrecision, ''));
    end;

    procedure RoundQty(Qty: Decimal; QtyRndingPrecision: Decimal; Direction: Text): Decimal
    begin
        OnBeforeQtyRndPrecision(QtyRndingPrecision);
        if QtyRndingPrecision = 0 then
            QtyRndingPrecision := 0.00001;

        if Direction = '' then
            exit(Round(Qty, QtyRndingPrecision))
        else
            exit(Round(Qty, QtyRndingPrecision, Direction));
    end;

    procedure RoundAndValidateQty(Qty: Decimal; QtyRndingPrecision: Decimal; FieldName: Text) QtyRounded: Decimal
    begin
        QtyRounded := RoundQty(Qty, QtyRndingPrecision);
        if (QtyRndingPrecision > 0) and (Qty <> QtyRounded) then
            Error(InvalidPrecisionErr, Qty, FieldName, 0.00001);

        exit(QtyRounded);
    end;

    procedure ValidateQtyIsBalanced(TotalQty: Decimal; TotalQtyBase: Decimal; QtyToHandle: Decimal; QtyToHandleBase: Decimal; QtyHandled: Decimal; QtyHandledBase: Decimal)
    var
        RemainingQty: Decimal;
        RemainingQtyBase: Decimal;
    begin
        RemainingQty := TotalQty - (QtyToHandle + QtyHandled);
        RemainingQtyBase := TotalQtyBase - (QtyToHandleBase + QtyHandledBase);

        if ((RemainingQty = 0) and (RemainingQtyBase <> 0)) or ((RemainingQtyBase = 0) and (RemainingQty <> 0)) then
            Error(QtyImbalanceDetectedErr);
    end;

    procedure RoundToItemRndPrecision(Qty: Decimal; ItemRndPrecision: Decimal) Result: Decimal
    begin
        Result := Round(RoundQty(Qty), ItemRndPrecision, '>');
        OnAfterRoundToItemRndPrecision(Qty, ItemRndPrecision, Result);
    end;

    procedure QtyRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeQtyRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    procedure CubageRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeCubageRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    procedure TimeRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeTimeRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    procedure WeightRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeWeightRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Unit of Measure", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ClearItemUnitOfMeasureRec()
    begin
        Clear(ItemUnitOfMeasure);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Resource Unit of Measure", 'OnBeforeModifyEvent', '', false, false)]
    local procedure ClearResourceUnitOfMeasureRec()
    begin
        Clear(ResourceUnitOfMeasure);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBaseQtyPerUnitOfMeasure(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; var QtyRounded: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyFromBasePerUnitOfMeasure(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; var QtyRounded: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundToItemRndPrecision(Qty: Decimal; ItemRndPrecision: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetQtyPerUnitOfMeasure(Item: Record Item; UnitOfMeasureCode: Code[10]; var QtyPerUnitOfMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetResQtyPerUnitOfMeasure(Resource: Record Resource; ResUnitOfMeasureCode: Code[10]; var QtyPerUnitOfMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCubageRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWeightRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;
}

