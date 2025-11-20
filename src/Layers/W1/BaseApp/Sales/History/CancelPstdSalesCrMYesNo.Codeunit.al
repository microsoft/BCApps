// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Utilities;

codeunit 1334 "Cancel PstdSalesCrM (Yes/No)"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    begin
        CancelCrMemo(Rec);
    end;

    var
        CancelPostedCrMemoQst: Label 'The posted sales credit memo will be canceled, and a sales invoice will be created and posted, which reverses the posted sales credit memo. Do you want to continue?';
        OpenPostedInvQst: Label 'The invoice was successfully created. Do you want to open the posted invoice?';

    local procedure CancelCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CancelledDocument: Record "Cancelled Document";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        CancelPostedSalesCrMemo.TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);
        if Confirm(CancelPostedCrMemoQst) then
            if CancelPostedSalesCrMemo.CancelPostedCrMemo(SalesCrMemoHeader) then
                if Confirm(OpenPostedInvQst) then begin
                    CancelledDocument.FindSalesCancelledCrMemo(SalesCrMemoHeader."No.");
                    SalesInvHeader.Get(CancelledDocument."Cancelled By Doc. No.");
                    IsHandled := false;
                    OnCancelInvoiceOnBeforePostedSalesInvoice(SalesInvHeader, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun(SalesInvHeader);
                    exit(true);
                end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelInvoiceOnBeforePostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;
}

