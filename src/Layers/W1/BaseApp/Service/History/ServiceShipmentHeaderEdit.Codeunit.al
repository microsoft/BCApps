// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 1414 "Service Shipment Header - Edit"
{
    Permissions = TableData "Service Shipment Header" = m;
    TableNo = "Service Shipment Header";

    procedure ModifyServiceShipment(var ServiceShptHeader2: Record "Service Shipment Header")
    var
        ServiceShptHeader: Record "Service Shipment Header";
    begin
        ServiceShptHeader := ServiceShptHeader2;
        ServiceShptHeader.LockTable();
        ServiceShptHeader.Find();
        ServiceShptHeader."Shipping Agent Code" := ServiceShptHeader2."Shipping Agent Code";
        ServiceShptHeader."Shipment Method Code" := ServiceShptHeader2."Shipment Method Code";
        OnBeforeServiceShptHeaderModify(ServiceShptHeader, ServiceShptHeader2);
        ServiceShptHeader.Modify();
        ServiceShptHeader2 := ServiceShptHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptHeaderModify(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentHeader2: Record "Service Shipment Header")
    begin
    end;
}
