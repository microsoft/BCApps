// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Handles execution of deposit test reports through extensible events.
/// Provides access to deposit validation and testing functionality via extensions.
/// </summary>
/// <remarks>
/// This codeunit enables deposit test report execution through extension implementations.
/// Used for validating deposit data before final processing or posting operations.
/// </remarks>
codeunit 1513 "Open Deposit Test Report"
{
    trigger OnRun()
    begin
        OnOpenDepositTestReport();
    end;

    /// <summary>
    /// Integration event for running deposit test reports.
    /// Allows extensions to provide deposit validation and testing functionality.
    /// </summary>
    /// <remarks>
    /// Raised from OnRun trigger to enable extension-based deposit test report execution.
    /// Typically handled by the Bank Deposits extension for deposit validation workflows.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositTestReport()
    begin
    end;

}
