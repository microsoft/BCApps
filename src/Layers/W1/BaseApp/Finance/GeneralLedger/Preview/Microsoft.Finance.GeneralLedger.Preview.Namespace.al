// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive posting preview functionality for general ledger transactions with simulation capabilities.
/// Enables users to preview posting operations without committing data, supporting validation and analysis workflows.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The preview system uses temporary records and event-driven architecture to simulate posting operations.
/// Core components include preview engines, event handlers, display pages, and transaction simulation frameworks.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Preview Generation:</b></term>
/// <description>Simulate posting operations in preview mode creating temporary entries for analysis without database commits</description>
/// </item>
/// <item>
/// <term><b>Entry Display:</b></term>
/// <description>Present preview results through specialized pages with hierarchical and flat views for comprehensive analysis</description>
/// </item>
/// <item>
/// <term><b>Validation Support:</b></term>
/// <description>Enable validation of posting logic, dimension assignments, and account distributions before actual posting</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with general journal posting, dimension management, and various ledger entry types. 
/// Supports custom preview scenarios through event subscriptions and extensible display frameworks.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include custom preview handlers, display customization events, and preview validation hooks. 
/// Supports custom entry types through OnGetEntries events and specialized preview page implementations.
/// </para>
/// </remarks>
namespace Microsoft.Finance.GeneralLedger.Preview;
