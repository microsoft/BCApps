// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 12261 "Service History Subscr. IT"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', true, true)]
    local procedure OnRunOnBeforeTestFieldNo(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader."Fattura Document Type" := ServiceInvoiceHeaderRec."Fattura Document Type";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Service Inv. - Update", 'OnAfterRecordChanged', '', true, true)]
    local procedure InvoiceOnAfterRecordChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or (ServiceInvoiceHeader."Fattura Document Type" <> xServiceInvoiceHeader."Fattura Document Type");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Shipment Header - Edit", 'OnBeforeServiceShptHeaderModify', '', true, true)]
    local procedure OnBeforeServiceShptHeaderModify(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentHeader2: Record "Service Shipment Header")
    begin
        ServiceShipmentHeader."3rd Party Loader Type" := ServiceShipmentHeader2."3rd Party Loader Type";
        ServiceShipmentHeader."3rd Party Loader No." := ServiceShipmentHeader2."3rd Party Loader No.";
        ServiceShipmentHeader."Additional Information" := ServiceShipmentHeader2."Additional Information";
        ServiceShipmentHeader."Additional Notes" := ServiceShipmentHeader2."Additional Notes";
        ServiceShipmentHeader."Additional Instructions" := ServiceShipmentHeader2."Additional Instructions";
        ServiceShipmentHeader."TDD Prepared By" := ServiceShipmentHeader2."TDD Prepared By";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Service Ship. - Update", 'OnAfterRecordChanged', '', true, true)]
    local procedure ShipmentOnAfterRecordChanged(var ServiceShipmentHeader: Record "Service Shipment Header"; xServiceShipmentHeader: Record "Service Shipment Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or
          (ServiceShipmentHeader."Additional Information" <> xServiceShipmentHeader."Additional Information") or
          (ServiceShipmentHeader."Additional Notes" <> xServiceShipmentHeader."Additional Notes") or
          (ServiceShipmentHeader."Additional Instructions" <> xServiceShipmentHeader."Additional Instructions") or
          (ServiceShipmentHeader."TDD Prepared By" <> xServiceShipmentHeader."TDD Prepared By") or
          (ServiceShipmentHeader."3rd Party Loader Type" <> xServiceShipmentHeader."3rd Party Loader Type") or
          (ServiceShipmentHeader."3rd Party Loader No." <> xServiceShipmentHeader."3rd Party Loader No.");
    end;
}