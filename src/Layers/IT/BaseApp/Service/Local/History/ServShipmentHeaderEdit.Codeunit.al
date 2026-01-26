#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 12191 "Serv. Shipment Header - Edit"
{
    Permissions = TableData "Service Shipment Header" = m;
    TableNo = "Service Shipment Header";
    ObsoleteReason = 'Replaced by W1 codeunit ServiceShipmentHeaderEdit';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    procedure ModifyServiceShipment(var ServiceShptHeader2: Record "Service Shipment Header")
    var
        ServiceShptHeader: Record "Service Shipment Header";
    begin
        ServiceShptHeader := ServiceShptHeader2;
        ServiceShptHeader.LockTable();
        ServiceShptHeader.Find();
        ServiceShptHeader."Shipping Agent Code" := ServiceShptHeader2."Shipping Agent Code";
        ServiceShptHeader."Shipment Method Code" := ServiceShptHeader2."Shipment Method Code";
        ServiceShptHeader."3rd Party Loader Type" := ServiceShptHeader2."3rd Party Loader Type";
        ServiceShptHeader."3rd Party Loader No." := ServiceShptHeader2."3rd Party Loader No.";
        ServiceShptHeader."Additional Information" := ServiceShptHeader2."Additional Information";
        ServiceShptHeader."Additional Notes" := ServiceShptHeader2."Additional Notes";
        ServiceShptHeader."Additional Instructions" := ServiceShptHeader2."Additional Instructions";
        ServiceShptHeader."TDD Prepared By" := ServiceShptHeader2."TDD Prepared By";
        OnBeforeServiceShptHeaderModify(ServiceShptHeader, ServiceShptHeader2);
        ServiceShptHeader.Modify();
        ServiceShptHeader2 := ServiceShptHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptHeaderModify(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentHeader2: Record "Service Shipment Header")
    begin
    end;
}
#endif
