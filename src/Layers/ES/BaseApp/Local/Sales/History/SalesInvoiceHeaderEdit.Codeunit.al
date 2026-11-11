// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

codeunit 10765 "Sales Invoice Header - Edit"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader := Rec;
        SalesInvoiceHeader.LockTable();
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader."Dispute Status" := Rec."Dispute Status";

        OnRunOnBeforeSalesInvoiceHeaderModify(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader.TestField("No.", Rec."No.");
        SalesInvoiceHeader.Modify();
        Rec := SalesInvoiceHeader;
        OnRunOnAfterSalesInvoiceHeaderEdit(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSalesInvoiceHeaderModify(var SalesInvoiceHeader: Record "Sales Invoice Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesInvoiceHeaderEdit(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

