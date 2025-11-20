// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.HumanResources.Payables;
using Microsoft.Sales.Receivables;

codeunit 599 "Exch. Rate Adjmt. Run Handler"
{
    trigger OnRun()
    begin
        RunExchangeRateAdjustment();
    end;

    local procedure RunExchangeRateAdjustment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunExchangeRateAdjustment(IsHandled);
        if IsHandled then
            exit;

        Report.Run(Report::"Exch. Rate Adjustment");
    end;

    procedure RunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCustExchRateAdjustment(GenJnlLine, TempCustLedgerEntry, IsHandled);
        if not IsHandled then
            ExchRateAdjmtProcess.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
    end;

    procedure RunVendExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunVendExchRateAdjustment(GenJnlLine, TempVendorLedgerEntry, IsHandled);
        if not IsHandled then
            ExchRateAdjmtProcess.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
    end;

    procedure RunEmplExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunEmplExchRateAdjustment(GenJnlLine, TempEmployeeLedgerEntry, IsHandled);
        if not IsHandled then
            ExchRateAdjmtProcess.AdjustExchRateEmpl(GenJnlLine, TempEmployeeLedgerEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunExchangeRateAdjustment(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunVendExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunEmplExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}

