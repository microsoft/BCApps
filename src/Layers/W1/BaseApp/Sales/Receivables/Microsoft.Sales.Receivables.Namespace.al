// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Manages customer ledger entries and payment applications for accounts receivable.
/// </summary>
/// <remarks>
/// The Sales.Receivables namespace provides functionality for:
/// - Storing and tracking customer ledger entries and their detailed sub-entries
/// - Applying and unapplying customer payments to invoices
/// - Managing payment tolerances and discounts
/// - Date compressing historical ledger entries for performance
/// - Querying customer balances and sales amounts
///
/// Key tables:
/// - Cust. Ledger Entry: Primary ledger entries for customer transactions
/// - Detailed Cust. Ledg. Entry: Sub-ledger entries for applications and adjustments
///
/// Key operations:
/// - Entry application: Matching payments to invoices
/// - Entry unapplication: Reversing previously applied entries
/// - Running balance calculation: Computing customer balances over time
/// </remarks>
namespace Microsoft.Sales.Receivables;
