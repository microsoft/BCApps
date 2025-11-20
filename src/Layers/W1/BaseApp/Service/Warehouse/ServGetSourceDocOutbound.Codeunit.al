// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Service.Document;

codeunit 6491 "Serv. Get Source Doc. Outbound"
{
    var
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";

    procedure CreateFromServiceOrder(ServiceHeader: Record "Service Header")
    begin
        OnBeforeCreateFromServiceOrder(ServiceHeader);
        GetSourceDocOutbound.ShowResult(CreateFromServiceOrderHideDialog(ServiceHeader));
    end;

    procedure CreateFromServiceOrderHideDialog(ServiceHeader: Record Microsoft.Service.Document."Service Header"): Boolean
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        FindWarehouseRequestForServiceOrder(WarehouseRequest, ServiceHeader);
        exit(GetSourceDocOutbound.CreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest));
    end;

    local procedure FindWarehouseRequestForServiceOrder(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.TestField("Release Status", ServiceHeader."Release Status"::"Released to Ship");
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetSourceFilter(Database::"Service Line", ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(WarehouseRequest, ServiceHeader);
#if not CLEAN25
        GetSourceDocOutbound.RunOnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(WarehouseRequest, ServiceHeader);
#endif
        GetSourceDocOutbound.GetRequireShipRqst(WarehouseRequest);

        OnAfterFindWarehouseRequestForServiceOrder(WarehouseRequest, ServiceHeader);
#if not CLEAN25
        GetSourceDocOutbound.RunOnAfterFindWarehouseRequestForServiceOrder(WarehouseRequest, ServiceHeader);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromServiceOrder(var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(var WarehouseRequest: Record "Warehouse Request"; var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForServiceOrder(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
}
