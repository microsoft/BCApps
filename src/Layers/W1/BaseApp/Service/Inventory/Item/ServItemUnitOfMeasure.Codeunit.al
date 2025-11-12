// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Service.Document;

codeunit 6480 "Serv. Item Unit of Measure"
{
    [EventSubscriber(ObjectType::Table, Database::"Item Unit of Measure", 'OnAfterCheckNoOutstandingQty', '', false, false)]
    local procedure OnAfterCheckNoOutstandingQty(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        CheckNoOutstandingQtyServiceLine(ItemUnitOfMeasure, xItemUnitOfMeasure);
    end;

    local procedure CheckNoOutstandingQtyServiceLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoOutstandingQtyServiceLine(ItemUnitOfMeasure, xItemUnitOfMeasure, ServiceLine, IsHandled);
#if not CLEAN25
        ItemUnitOfMeasure.RunOnBeforeCheckNoOutstandingQtyServiceLine(ItemUnitOfMeasure, xItemUnitOfMeasure, ServiceLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("No.", ItemUnitOfMeasure."Item No.");
        ServiceLine.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ServiceLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not ServiceLine.IsEmpty() then
            Error(
            ItemUnitOfMeasure.GetCannotModifyUnitOfMeasureErr(), ItemUnitOfMeasure.TableCaption(), xItemUnitOfMeasure.Code, ItemUnitOfMeasure."Item No.",
            ServiceLine.TableCaption(), ServiceLine.FieldCaption("Qty. to Ship"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoOutstandingQtyServiceLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;
}
