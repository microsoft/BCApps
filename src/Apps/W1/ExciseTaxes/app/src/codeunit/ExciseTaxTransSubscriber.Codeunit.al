// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Sustainability.ExciseTax;

codeunit 7413 "Excise Tax Trans Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"Sust. Excise Taxes Trans. Log", 'OnAfterCopyFromSustainabilityExciseJnlLine', '', false, false)]
    local procedure OnAfterCopyFromSustainabilityExciseJnlLine(var SustExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log"; SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line")
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if not ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            exit;

        SustExciseTaxesTransactionLog."Excise Tax Type" := SustainabilityExciseJnlLine."Excise Tax Type";
        SustExciseTaxesTransactionLog."Tax Rate %" := SustainabilityExciseJnlLine."Tax Rate %";
        SustExciseTaxesTransactionLog."Tax Amount" := SustainabilityExciseJnlLine."Tax Amount";
        SustExciseTaxesTransactionLog.Quantity := SustainabilityExciseJnlLine.Quantity;
        SustExciseTaxesTransactionLog."Excise Tax UOM" := SustainabilityExciseJnlLine."Excise Tax UOM";
        SustExciseTaxesTransactionLog."Excise Entry Type" := SustainabilityExciseJnlLine."Excise Entry Type";
        SustExciseTaxesTransactionLog."FA Ledger Entry No." := SustainabilityExciseJnlLine."FA Ledger Entry No.";
        ExciseTaxCalculation.UpdateItemLedgerEntryExciseTaxInfo(SustExciseTaxesTransactionLog);
        ExciseTaxCalculation.UpdateFALedgerEntryExciseTaxInfo(SustExciseTaxesTransactionLog);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sust. Excise Jnl.-Check", 'OnBeforeTestEmissionAmount', '', false, false)]
    local procedure OnBeforeTestEmissionAmount(SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line"; var IsHandled: Boolean)
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sust. Excise Jnl. Line", 'OnValidateSourceNoBeforeTestFieldPartnerNo', '', false, false)]
    local procedure OnValidateSourceNoBeforeTestFieldPartnerNo(var SustainabilityExciseJnlLine: Record "Sust. Excise Jnl. Line"; var IsHandled: Boolean)
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        if ExciseTaxCalculation.IsExciseTaxEntry(SustainabilityExciseJnlLine) then
            IsHandled := true;
    end;
}