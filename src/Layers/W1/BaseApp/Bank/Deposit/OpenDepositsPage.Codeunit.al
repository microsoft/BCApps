// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Handles navigation to the main deposits page through extensible events.
/// Provides a bridge for opening deposit list functionality via the Bank Deposits extension.
/// </summary>
/// <remarks>
/// This codeunit delegates deposit page opening to extension implementations through integration events.
/// Used when direct page access is not available and extension-based navigation is required.
/// </remarks>
codeunit 1500 "Open Deposits Page"
{
    trigger OnRun()
    begin
        OnOpenDepositsPage();
    end;

    /// <summary>
    /// Integration event for opening the main deposits page.
    /// Allows extensions to provide the actual deposit page implementation.
    /// </summary>
    /// <remarks>
    /// Raised from OnRun trigger to enable extension-based deposit page navigation.
    /// Typically handled by the Bank Deposits extension.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositsPage()
    begin
    end;
}
