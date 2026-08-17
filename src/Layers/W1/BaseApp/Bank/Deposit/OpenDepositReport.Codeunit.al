// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Handles execution of deposit reports through extensible events.
/// Provides access to deposit documentation and summary reporting via extensions.
/// </summary>
/// <remarks>
/// This codeunit delegates deposit report execution to extension implementations.
/// Enables deposit report generation when direct report access is not available.
/// </remarks>
codeunit 1507 "Open Deposit Report"
{
    trigger OnRun()
    begin
        OnOpenDepositReport();
    end;

    /// <summary>
    /// Integration event for running deposit reports.
    /// Allows extensions to provide deposit reporting and documentation functionality.
    /// </summary>
    /// <remarks>
    /// Raised from OnRun trigger to enable extension-based deposit report execution.
    /// Typically implemented by the Bank Deposits extension for deposit documentation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositReport()
    begin
    end;

}
