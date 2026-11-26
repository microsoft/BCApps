// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.VAT.Calculation;

codeunit 7000082 "Purchase History Subscr. ES"
{
    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', false, false)]
    local procedure InvoiceOnCalcVATAmountLinesOnBeforeInsertLine(PurchInvHeader: Record "Purch. Inv. Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if PurchInvHeader."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnAfterGetVATPct', '', false, false)]
    local procedure InvoiceOnAfterGetVATPct(var PurchInvLine: Record "Purch. Inv. Line"; var VATPct: Decimal)
    begin
        VATPct += PurchInvLine."EC %";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', false, false)]
    local procedure CreditMemoOnCalcVATAmountLinesOnBeforeInsertLine(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if PurchCrMemoHdr."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Line", 'OnAfterGetVATPct', '', false, false)]
    local procedure CreditMemoOnAfterGetVATPct(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var VATPct: Decimal)
    begin
        VATPct += PurchCrMemoLine."EC %";
    end;
}
