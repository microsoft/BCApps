// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive intercompany inbox functionality for receiving and processing transactions from partner companies.
/// Manages the complete lifecycle of incoming IC transactions including import, validation, acceptance, and conversion to local documents.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The inbox system uses a transaction-based approach where IC Inbox Transaction records serve as the main entry point,
/// with related tables storing detailed information for journal lines, sales documents, and purchase documents.
/// Processed transactions are archived in handled inbox tables for audit trail purposes.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Transaction Import:</b></term>
/// <description>Import IC outbox data from partner companies via file exchange or direct API integration, creating inbox transaction records</description>
/// </item>
/// <item>
/// <term><b>Transaction Review:</b></term>
/// <description>Review imported transactions through inbox workspace, validate data, and set acceptance actions (Accept, Return, Cancel)</description>
/// </item>
/// <item>
/// <term><b>Transaction Processing:</b></term>
/// <description>Execute acceptance actions to convert inbox transactions to local documents and journal entries, with automatic posting</description>
/// </item>
/// <item>
/// <term><b>Archive Management:</b></term>
/// <description>Move completed transactions to handled inbox tables for historical tracking and audit purposes</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with Intercompany Outbox for transaction exchange, General Ledger for journal posting, 
/// Sales and Purchase modules for document creation, and Dimension system for cross-company dimension mapping.
/// Supports file-based and API-based data exchange with multiple IC partners.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include transaction import customization events, acceptance validation hooks, 
/// and document conversion events. Custom import procedures can be implemented for non-standard data formats.
/// Transaction processing supports custom validation and approval workflows through integration events.
/// </para>
/// </remarks>
namespace Microsoft.Intercompany.Inbox;
