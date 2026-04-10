// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides storage and management for posted sales documents including invoices, shipments, credit memos, and return receipts.
/// Supports document viewing, printing, correction, and cancellation operations for completed sales transactions.
/// </summary>
/// <remarks>
/// Core tables: Sales Invoice Header, Sales Shipment Header, Sales Cr.Memo Header, Return Receipt Header, and their corresponding line tables.
/// Correction and cancellation codeunits enable reversing posted invoices and credit memos while maintaining full audit trails.
/// Document printing reports include Standard Sales Invoice, Standard Sales Shipment, Standard Sales Credit Memo, and Sales Return Receipt.
/// </remarks>
namespace Microsoft.Sales.History;
