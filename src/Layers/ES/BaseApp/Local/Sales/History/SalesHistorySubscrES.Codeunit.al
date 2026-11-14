// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.VAT.Calculation;

codeunit 7000083 "Sales History Subscr. ES"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', false, false)]
    local procedure InvoiceOnCalcVATAmountLinesOnBeforeInsertLine(SalesInvHeader: Record "Sales Invoice Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if SalesInvHeader."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Line", 'OnAfterGetVATPct', '', false, false)]
    local procedure InvoiceOnAfterGetVATPct(var SalesInvoiceLine: Record "Sales Invoice Line"; var VATPct: Decimal)
    begin
        VATPct += SalesInvoiceLine."EC %";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', false, false)]
    local procedure CreditMemoOnCalcVATAmountLinesOnBeforeInsertLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if SalesCrMemoHeader."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Line", 'OnAfterGetVATPct', '', false, false)]
    local procedure CreditMemoOnAfterGetVATPct(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var VATPct: Decimal)
    begin
        VATPct += SalesCrMemoLine."EC %";
    end;
}
