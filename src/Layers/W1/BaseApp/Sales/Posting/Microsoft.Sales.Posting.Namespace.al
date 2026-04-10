// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides functionality for posting sales documents to general ledger, customer ledger, and inventory ledger entries.
/// </summary>
/// <remarks>
/// This namespace contains codeunits that handle the posting process for various sales document types including orders, invoices, credit memos, and return orders.
/// Key posting operations include creating ledger entries, handling prepayments, managing deferrals, and supporting background posting via job queues.
/// The namespace also provides integration events for customizing posting behavior and validation logic.
/// </remarks>
namespace Microsoft.Sales.Posting;
