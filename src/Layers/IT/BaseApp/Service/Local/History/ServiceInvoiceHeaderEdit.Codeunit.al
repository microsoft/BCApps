#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 12187 "Service Invoice Header - Edit"
{
    Permissions = TableData "Service Invoice Header" = rm;
    TableNo = "Service Invoice Header";
    ObsoleteReason = 'Replaced by W1 codeunit ServiceInvHeaderEdit';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader := Rec;
        ServiceInvoiceHeader.LockTable();
        ServiceInvoiceHeader.Find();
        ServiceInvoiceHeader."Fattura Document Type" := Rec."Fattura Document Type";
        OnRunOnBeforeServiceInvoiceHeaderModify(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader.TestField("No.", Rec."No.");
        ServiceInvoiceHeader.Modify();
        Rec := ServiceInvoiceHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceInvoiceHeaderModify(var ServiceInvoiceHeader: Record "Service Invoice Header"; FromServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}
#endif
