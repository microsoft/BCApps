// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Purchases.History;
using Microsoft.Sales.History;

codeunit 11310 "VAT Amount Line Mgt. BE"
{
    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnInsertLineOnBeforeModify', '', false, false)]
    local procedure OnInsertLineOnBeforeModify(var VATAmountLine: Record "VAT Amount Line"; FromVATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."VAT Base (Lowered)" += FromVATAmountLine."VAT Base (Lowered)";
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnApplyNonDeductibleVATOnBeforeModify', '', false, false)]
    local procedure OnApplyNonDeductibleVATOnBeforeModify(var VATAmountLine: Record "VAT Amount Line"; NonDeductibleVAT: Decimal)
    begin
        VATAmountLine."VAT Base (Lowered)" += NonDeductibleVAT;
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnAfterCopyFromPurchInvLine', '', false, false)]
    local procedure OnAfterCopyFromPurchInvLine(var VATAmountLine: Record "VAT Amount Line"; PurchInvLine: Record "Purch. Inv. Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        VATAmountLine."VAT Base (Lowered)" := PurchInvLine."VAT Base Amount";
        if VATAmountLine."VAT Calculation Type" = VATAmountLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
            if PurchInvHeader.Get(PurchInvLine."Document No.") then;
            if PurchInvHeader."VAT Base Discount %" <> 0 then
                VATAmountLine."VAT Base (Lowered)" := VATAmountLine."VAT Base (Lowered)" * (1 - PurchInvHeader."VAT Base Discount %" / 100);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnAfterCopyFromPurchCrMemoLine', '', false, false)]
    local procedure OnAfterCopyFromPurchCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        VATAmountLine."VAT Base (Lowered)" := PurchCrMemoLine."VAT Base Amount";
        if VATAmountLine."VAT Calculation Type" = VATAmountLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
            if PurchCrMemoHdr.Get(PurchCrMemoLine."Document No.") then;
            if PurchCrMemoHdr."VAT Base Discount %" <> 0 then
                VATAmountLine."VAT Base (Lowered)" := VATAmountLine."VAT Base (Lowered)" * (1 - PurchCrMemoHdr."VAT Base Discount %" / 100);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnAfterCopyFromSalesInvLine', '', false, false)]
    local procedure OnAfterCopyFromSalesInvLine(var VATAmountLine: Record "VAT Amount Line"; SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        VATAmountLine."VAT Base (Lowered)" := SalesInvoiceLine."VAT Base Amount";
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnAfterCopyFromSalesCrMemoLine', '', false, false)]
    local procedure OnAfterCopyFromSalesCrMemoLine(var VATAmountLine: Record "VAT Amount Line"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        VATAmountLine."VAT Base (Lowered)" := SalesCrMemoLine."VAT Base Amount";
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnCopyFromPurchInvLineOnAfterSetLineAmount', '', false, false)]
    local procedure OnCopyFromPurchInvLineOnAfterSetLineAmount(var VATAmountLine: Record "VAT Amount Line"; var PurchInvLine: Record "Purch. Inv. Line");
    begin
        if VATAmountLine."VAT Calculation Type" = VATAmountLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
            VATAmountLine."VAT %" := 0;
            VATAmountLine."VAT Amount" := 0;
            VATAmountLine."Amount Including VAT" := PurchInvLine.Amount;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Amount Line", 'OnCopyFromPurchCrMemoLineOnAfterSetLineAmount', '', false, false)]
    local procedure OnCopyFromPurchCrMemoLineOnAfterSetLineAmount(var VATAmountLine: Record "VAT Amount Line"; var PurchCrMemoLine: Record "Purch. Cr. Memo Line");
    begin
        if VATAmountLine."VAT Calculation Type" = VATAmountLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
            VATAmountLine."VAT %" := 0;
            VATAmountLine."VAT Amount" := 0;
            VATAmountLine."Amount Including VAT" := PurchCrMemoLine.Amount;
        end;
    end;
}