// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Utilities;

codeunit 1323 "Cancel PstdSalesInv (Yes/No)"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    begin
        CancelInvoice(Rec);
    end;

    var
        CancelPostedInvoiceQst: Label 'This invoice was posted from a sales order. To cancel it, a sales credit memo will be created and posted. The quantities from the original sales order will be restored, provided the sales order still exists.\ \Do you want to continue?';
        OpenPostedCreditMemoQst: Label 'A credit memo was successfully created. Do you want to open the posted credit memo?';

    procedure CancelInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnCancelInvoiceOnBeforeTestCorrectInvoiceIsAllowed(SalesInvoiceHeader, IsHandled);
        if not IsHandled then
            CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
        if Confirm(CancelPostedInvoiceQst) then
            if CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader) then
                if Confirm(OpenPostedCreditMemoQst) then begin
                    CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No.");
                    SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.");
                    IsHandled := false;
                    OnCancelInvoiceOnBeforePostedSalesCreditMemo(SalesCrMemoHeader, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun(SalesCrMemoHeader);
                    exit(true);
                end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelInvoiceOnBeforePostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelInvoiceOnBeforeTestCorrectInvoiceIsAllowed(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;
}

