// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Handles navigation to deposit list pages through extensible events.
/// Provides access to deposit collection views and summary information via extensions.
/// </summary>
/// <remarks>
/// This codeunit enables deposit list page access through extension implementations.
/// Used for displaying multiple deposit documents with filtering and selection capabilities.
/// </remarks>
codeunit 1506 "Open Deposit List Page"
{
    trigger OnRun()
    begin
        OnOpenDepositListPage();
    end;

    /// <summary>
    /// Integration event for opening deposit list pages.
    /// Allows extensions to provide deposit collection viewing functionality.
    /// </summary>
    /// <remarks>
    /// Raised from OnRun trigger to enable extension-based deposit list navigation.
    /// Typically handled by the Bank Deposits extension for deposit overview and selection.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositListPage()
    begin
    end;
}
