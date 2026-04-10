// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides core functionality for General Ledger entry management, audit trails, and financial transaction history in Microsoft Business Central.
/// Handles the ledger and register aspects of the General Ledger subsystem, focusing on transaction storage, register management, and entry navigation.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The General Ledger Ledger system is built on a dual-table architecture with G/L Entry for transaction storage and G/L Register for batch tracking, 
/// supported by preview functionality and optimized query access patterns for high-volume financial data processing.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Transaction Recording:</b></term>
/// <description>G/L entries created through posting processes with automatic register assignment, dimension capture, and complete audit trail preservation</description>
/// </item>
/// <item>
/// <term><b>Entry Navigation and Analysis:</b></term>
/// <description>Real-time access to transaction data through optimized pages and queries, with batch-level analysis via register relationships and multi-dimensional filtering</description>
/// </item>
/// <item>
/// <term><b>Data Maintenance:</b></term>
/// <description>Preview validation before posting, controlled entry modifications with audit compliance, and historical data compression for performance optimization</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with G/L Account master data, Dimension framework, Currency system, and Foundation audit codes. 
/// Provides data foundation for financial statements, subsidiary ledgers, and regulatory reporting requirements.
/// Supports source document integration from sales, purchase, and journal posting processes.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include entry modification events, register navigation customization, and query optimization for specialized reporting. 
/// Commonly extended for industry-specific audit trails, custom dimension analysis, and third-party system integration requirements.
/// </para>
/// </remarks>
namespace Microsoft.Finance.GeneralLedger.Ledger;
