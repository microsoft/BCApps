// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Defines order preferences for applying entries during net customer/vendor balance processing.
/// Controls document selection priority when multiple open entries exist for netting operations.
/// </summary>
/// <remarks>
/// Used by net balance processing to determine which documents to apply first.
/// Supports finance charge memo priority, invoice priority, or entry number-based ordering.
/// Affects the sequence of document application in customer-vendor netting scenarios.
/// </remarks>
enum 109 "Net Cust/Vend Balances Order"
{
    Extensible = true;

    /// <summary>
    /// Apply finance charge memos before other document types during netting operations.
    /// </summary>
    value(0; "Fin. Ch. Memo First") { Caption = 'Fin. Ch. Memo First'; }
    /// <summary>
    /// Apply invoices before other document types during netting operations.
    /// </summary>
    value(1; "Invoices First") { Caption = 'Invoices First'; }
    /// <summary>
    /// Apply entries in sequential order based on entry number assignment.
    /// </summary>
    value(2; "By Entry No.") { Caption = 'By Entry No.'; }
}
