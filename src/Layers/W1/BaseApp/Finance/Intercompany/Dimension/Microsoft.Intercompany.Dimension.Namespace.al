// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides comprehensive dimension management for intercompany transactions in Business Central.
/// Enables consistent dimension structures and mapping across multiple partner companies.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The intercompany dimension system is built on a mapping-based architecture where local dimensions
/// are mapped to standardized intercompany dimension structures for cross-company consistency.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Dimension Setup:</b></term>
/// <description>Create intercompany dimensions and values, establish mappings to local dimensions, configure dimension hierarchies</description>
/// </item>
/// <item>
/// <term><b>Transaction Processing:</b></term>
/// <description>Apply intercompany dimensions to transactions, validate dimension mappings, synchronize dimension data across partners</description>
/// </item>
/// <item>
/// <term><b>Import/Export:</b></term>
/// <description>Exchange dimension definitions between partners, maintain consistent dimension structures, update mappings as needed</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger dimensions for local mapping, intercompany transaction processing for dimension data exchange,
/// and partner management for dimension synchronization. Uses XMLPort functionality for dimension structure import/export.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include dimension validation events, mapping transformation hooks, and custom dimension type support.
/// Supports custom dimension hierarchies through OnBeforeSelectingDimensions events and dimension mapping customization.
/// </para>
/// </remarks>
namespace Microsoft.Intercompany.Dimension;
