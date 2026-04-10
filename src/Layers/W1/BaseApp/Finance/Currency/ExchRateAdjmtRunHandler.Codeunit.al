// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Provides handlers for running exchange rate adjustment procedures.
/// Coordinates adjustment processing for customers, vendors, and employees
/// with extensibility support through integration events.
/// </summary>
/// <remarks>
/// Acts as an interface between user requests and exchange rate adjustment processing.
/// Includes integration events for custom adjustment logic and error handling.
/// </remarks>
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

    /// <summary>
    /// Runs exchange rate adjustment for customer accounts using provided journal line and ledger entries.
    /// </summary>
    /// <param name="GenJnlLine">General journal line with adjustment posting information</param>
    /// <param name="TempCustLedgerEntry">Temporary customer ledger entries to be adjusted</param>
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

    /// <summary>
    /// Runs exchange rate adjustment for vendor accounts using provided journal line and ledger entries.
    /// </summary>
    /// <param name="GenJnlLine">General journal line with adjustment posting information</param>
    /// <param name="TempVendorLedgerEntry">Temporary vendor ledger entries to be adjusted</param>
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

    /// <summary>
    /// Runs exchange rate adjustment for employee accounts using provided journal line and ledger entries.
    /// </summary>
    /// <param name="GenJnlLine">General journal line with adjustment posting information</param>
    /// <param name="TempEmployeeLedgerEntry">Temporary employee ledger entries to be adjusted</param>
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

    /// <summary>
    /// Integration event raised before running general exchange rate adjustment.
    /// Enables custom logic to override or supplement standard adjustment processing.
    /// </summary>
    /// <param name="IsHandled">Set to true to skip standard adjustment processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunExchangeRateAdjustment(var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before running customer exchange rate adjustment.
    /// Enables custom processing of customer adjustment logic.
    /// </summary>
    /// <param name="GenJnlLine">General journal line for posting adjustments</param>
    /// <param name="TempCustLedgerEntry">Customer ledger entries to be adjusted</param>
    /// <param name="IsHandled">Set to true to skip standard customer adjustment</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before running vendor exchange rate adjustment.
    /// Enables custom processing of vendor adjustment logic.
    /// </summary>
    /// <param name="GenJnlLine">General journal line for posting adjustments</param>
    /// <param name="TempVendorLedgerEntry">Vendor ledger entries to be adjusted</param>
    /// <param name="IsHandled">Set to true to skip standard vendor adjustment</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunVendExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before running employee exchange rate adjustment.
    /// Enables custom processing of employee adjustment logic.
    /// </summary>
    /// <param name="GenJnlLine">General journal line for posting adjustments</param>
    /// <param name="TempEmployeeLedgerEntry">Employee ledger entries to be adjusted</param>
    /// <param name="IsHandled">Set to true to skip standard employee adjustment</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunEmplExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}

