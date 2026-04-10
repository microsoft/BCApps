// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides archival storage and management for sales documents including quotes, orders, blanket orders, and return orders.
/// </summary>
/// <remarks>
/// <para><b>Key Capabilities:</b></para>
/// <list type="bullet">
///   <item>Storage of historical sales document versions</item>
///   <item>Archive header and line data preservation</item>
///   <item>Version tracking for archived documents</item>
///   <item>Archived document viewing and printing</item>
/// </list>
/// <para><b>Entry Points:</b> Use <c>Sales Header Archive</c> table for archived document data,
/// list pages like <c>Sales Order Archives</c> for viewing archived documents.</para>
/// </remarks>
namespace Microsoft.Sales.Archive;
