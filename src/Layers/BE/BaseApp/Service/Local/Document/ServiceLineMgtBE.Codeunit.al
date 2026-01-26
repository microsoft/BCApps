// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 11309 "Service Line Mgt. BE"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnUpdateVATAmountsOnAfterCalculateVATBaseAmount', '', false, false)]
    local procedure OnUpdateVATAmountsOnAfterCalculateVATBaseAmount(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var Currency: Record Currency; TotalAmount: Decimal; TotalVATBaseAmount: Decimal)
    begin
        if ServiceLine."VAT %" <> 0 then
            ServiceLine."VAT Base Amount" :=
                Round(
                    (TotalAmount + ServiceLine.Amount) * (1 - ServiceLine.GetVatBaseDiscountPct(ServiceHeader) / 100),
                    Currency."Amount Rounding Precision") -
                TotalVATBaseAmount
        else
            ServiceLine."VAT Base Amount" := ServiceLine.Amount;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnCalcVATAmountLinesOnBeforeVATAmountLineModifyShipping', '', false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyShipping(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."VAT Base (Lowered)" += ServiceLine."VAT Base Amount";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnCalcVATAmountLinesOnBeforeVATAmountLineModifyElseCase', '', false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineModifyElseCase(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."VAT Base (Lowered)" += ServiceLine."VAT Base Amount";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceInclVAT', '', false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceInclVAT(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var VATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; NewAmount: Decimal; var NewVATBaseAmount: Decimal)
    begin
        if (ServiceLine."VAT %" <> 0) and (VATAmountLine.CalcLineAmount() <> 0) then
            NewVATBaseAmount :=
                TempVATAmountLineRemainder."VAT Base (Lowered)" +
                VATAmountLine."VAT Base" * (1 - ServiceLine.GetVatBaseDiscountPct(ServiceHeader) / 100) *
                ServiceLine.CalcLineAmount() / VATAmountLine.CalcLineAmount()
        else
            NewVATBaseAmount := NewAmount;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceExclVAT', '', false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceExclVAT(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var VATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; NewAmount: Decimal; var NewVATBaseAmount: Decimal)
    begin
        if (ServiceLine."VAT %" <> 0) and (VATAmountLine.CalcLineAmount() <> 0) then
            NewVATBaseAmount :=
                TempVATAmountLineRemainder."VAT Base (Lowered)" +
                VATAmountLine."VAT Base" * (1 - ServiceLine.GetVatBaseDiscountPct(ServiceHeader) / 100) *
                ServiceLine.CalcLineAmount() / VATAmountLine.CalcLineAmount()
        else
            NewVATBaseAmount := NewAmount;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnUpdateVATOnLinesOnAfterSetVATBaseAmountGeneral', '', false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetVATBaseAmountGeneral(var ServiceLine: Record "Service Line"; var VATAmountLine: Record "VAT Amount Line"; var Currency: Record Currency; NewVATBaseAmount: Decimal)
    begin
        if ServiceLine."VAT %" <> 0 then
            ServiceLine."VAT Base Amount" := Round(NewVATBaseAmount, Currency."Amount Rounding Precision")
        else
            ServiceLine."VAT Base Amount" := ServiceLine.Amount;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnUpdateVATOnLinesOnAfterSetNewVATBaseAmountPriceExclVAT', '', false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var ServiceLine: Record "Service Line"; NewVATBaseAmount: Decimal)
    begin
        TempVATAmountLineRemainder."VAT Base (Lowered)" := NewVATBaseAmount - ServiceLine."VAT Base Amount";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', false, false)]
    local procedure ServiceInvoiceLineOnCalcVATAmountLinesOnBeforeInsertLine(ServInvHeader: Record "Service Invoice Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        TempVATAmountLine."VAT Base (Lowered)" := TempVATAmountLine."VAT Base" * (1 - ServInvHeader."Payment Discount %" / 100);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnAfterCopyToVATAmountLine', '', false, false)]
    local procedure ServiceInvoiceLineOnAfterCopyToVATAmountLine(ServiceInvoiceLine: Record "Service Invoice Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."VAT Base (Lowered)" := ServiceInvoiceLine."VAT Base Amount";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', false, false)]
    local procedure ServiceCrMemoLineOnCalcVATAmountLinesOnBeforeInsertLine(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        TempVATAmountLine."VAT Base (Lowered)" := TempVATAmountLine."VAT Base" * (1 - ServiceCrMemoHeader."Payment Discount %" / 100);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnAfterCopyToVATAmountLine', '', false, false)]
    local procedure ServiceCrMemoLineOnAfterCopyToVATAmountLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."VAT Base (Lowered)" := ServiceCrMemoLine."VAT Base Amount";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Amounts Mgt.", 'OnDivideAmountOnBeforeTempVATAmountLineRemainderModify', '', false, false)]
    local procedure OnDivideAmountOnBeforeTempVATAmountLineRemainderModify(var ServiceLine: Record "Service Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var ServiceHeader: Record "Service Header"; var Currency: Record Currency)
    begin
        if TempVATAmountLine.CalcLineAmount() <> 0 then begin
            TempVATAmountLineRemainder."Pmt. Discount Amount" :=
                TempVATAmountLineRemainder."Pmt. Discount Amount" +
                TempVATAmountLine."VAT Base" * ServiceHeader."Payment Discount %" / 100 *
                ServiceLine.CalcLineAmount() / TempVATAmountLine.CalcLineAmount();
            ServiceLine."Pmt. Discount Amount" :=
                Round(TempVATAmountLineRemainder."Pmt. Discount Amount", Currency."Amount Rounding Precision");
            TempVATAmountLineRemainder."Pmt. Discount Amount" :=
                TempVATAmountLineRemainder."Pmt. Discount Amount" - ServiceLine."Pmt. Discount Amount";
        end;
    end;
}