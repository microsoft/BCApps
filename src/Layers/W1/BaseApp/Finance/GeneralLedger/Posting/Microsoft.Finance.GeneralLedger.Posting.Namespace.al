// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides core general journal posting functionality with comprehensive validation, batch processing, and extensibility support.
/// Handles individual line posting, batch operations, print integration, and job queue-based processing for general ledger transactions.
/// </summary>
/// <remarks>
/// <para>
/// <b>Architecture:</b>
/// The posting system is built on a layered architecture with specialized codeunits for line-level posting, batch operations, 
/// and background processing. Core components include posting engines, validation frameworks, and extensible event publishers.
/// </para>
/// <para>
/// <b>Key Workflows:</b>
/// </para>
/// <list type="number">
/// <item>
/// <term><b>Individual Line Posting:</b></term>
/// <description>Validate and post single journal lines with comprehensive business rule enforcement and integration event support</description>
/// </item>
/// <item>
/// <term><b>Batch Processing:</b></term>
/// <description>Process multiple journal lines with balance validation, allocation handling, and recurring entry management</description>
/// </item>
/// <item>
/// <term><b>Background Posting:</b></term>
/// <description>Schedule posting operations through job queue entries for performance optimization and user experience enhancement</description>
/// </item>
/// </list>
/// <para>
/// <b>Integration Points:</b>
/// Integrates with General Ledger entries, dimension management, VAT processing, and fixed asset journals. 
/// Supports data exchange framework integration and intercompany transaction handling.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Key extension points include pre/post validation events, custom posting logic hooks, and balance checking customization. 
/// Supports custom allocation methods through OnBeforePostAllocations and posting workflow customization via multiple integration events.
/// </para>
/// </remarks>
namespace Microsoft.Finance.GeneralLedger.Posting;
