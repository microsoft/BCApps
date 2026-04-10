// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 1412 "Service Inv. Header - Edit"
{
    Permissions = TableData "Service Invoice Header" = rm;
    TableNo = "Service Invoice Header";

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader := Rec;
        ServiceInvoiceHeader.LockTable();
        ServiceInvoiceHeader.Find();
        OnRunOnBeforeAssignNewValues(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader."Payment Method Code" := Rec."Payment Method Code";
        ServiceInvoiceHeader."Payment Reference" := Rec."Payment Reference";
        ServiceInvoiceHeader."Company Bank Account Code" := Rec."Company Bank Account Code";
        OnOnRunOnBeforeTestFieldNo(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader.TestField("No.", Rec."No.");
        ServiceInvoiceHeader.Modify();
        Rec := ServiceInvoiceHeader;

        OnRunOnAfterServiceInvoiceHeaderEdit(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeAssignNewValues(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnRunOnBeforeTestFieldNo(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterServiceInvoiceHeaderEdit(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}

