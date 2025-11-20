// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;
using Microsoft.Service.Item;

codeunit 6488 "Serv. Undo Sales Shipment Line"
{
    var
        ServiceItem: Record "Service Item";
#if not CLEAN25
        UndoSalesShipmentLine: Codeunit "Undo Sales Shipment Line";
#endif
        DeleteServiceItemsQst: Label 'Some shipment lines may have unused service items. Do you want to delete them?';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnAfterCheckSalesShipmentLines', '', false, false)]
    local procedure OnAfterCheckSalesShipmentLines(var SalesShipmentLine: Record "Sales Shipment Line"; var UndoSalesShptLineParams: Record "Undo Sales Shpt. Line Params")
    begin
        ServiceItem.SetCurrentKey("Sales/Serv. Shpt. Document No.");
        ServiceItem.SetRange("Sales/Serv. Shpt. Document No.", SalesShipmentLine."Document No.");
        if ServiceItem.FindFirst() then
            UndoSalesShptLineParams."Delete Service Items" := ShouldDeleteServItems(SalesShipmentLine, ServiceItem, UndoSalesShptLineParams);
    end;

    local procedure ShouldDeleteServItems(var SalesShipmentLine: Record "Sales Shipment Line"; var ServiceItem: Record "Service Item"; var UndoSalesShptLineParams: Record "Undo Sales Shpt. Line Params") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeleteServItems(SalesShipmentLine, ServiceItem, UndoSalesShptLineParams."Hide Dialog", Result, IsHandled);
#if not CLEAN25
        UndoSalesShipmentLine.RunOnBeforeGetDeleteServItems(SalesShipmentLine, ServiceItem, UndoSalesShptLineParams."Hide Dialog", Result, IsHandled);
#endif
        if IsHandled then
            exit;

        if not UndoSalesShptLineParams."Hide Dialog" then
            Result := Confirm(DeleteServiceItemsQst, true)
        else
            Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnBeforeDeleteRelatedItems', '', false, false)]
    local procedure OnBeforeDeleteRelatedItems(var SalesShipmentLine: Record "Sales Shipment Line"; UndoSalesShptLineParams: Record "Undo Sales Shpt. Line Params" temporary)
    begin
        if UndoSalesShptLineParams."Delete Service Items" then
            DeleteSalesShptLineServItems(SalesShipmentLine);
    end;

    local procedure DeleteSalesShptLineServItems(SalesShipmentLine2: Record "Sales Shipment Line")
    var
        ServiceItem2: Record "Service Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteSalesShptLineServItems(SalesShipmentLine2, IsHandled);
#if not CLEAN25
        UndoSalesShipmentLine.RunOnBeforeDeleteSalesShptLineServItems(SalesShipmentLine2, IsHandled);
#endif
        if IsHandled then
            exit;

        ServiceItem2.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        ServiceItem2.SetRange("Sales/Serv. Shpt. Document No.", SalesShipmentLine2."Document No.");
        ServiceItem2.SetRange("Sales/Serv. Shpt. Line No.", SalesShipmentLine2."Line No.");
        ServiceItem2.SetRange("Shipment Type", ServiceItem."Shipment Type"::Sales);
        if ServiceItem2.Find('-') then
            repeat
                if ServiceItem2.CheckIfCanBeDeleted() = '' then
                    if ServiceItem2.Delete(true) then;
            until ServiceItem2.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeleteServItems(SalesShipmentLine: Record "Sales Shipment Line"; var ServiceItem: Record "Service Item"; HideDialog: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesShptLineServItems(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;
}
