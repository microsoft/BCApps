// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

/// <summary>
/// Defines source types for intercompany transactions to categorize origin of IC data.
/// Identifies whether transactions originated from journals, sales documents, or purchase documents.
/// </summary>
/// <remarks>
/// Used for transaction tracking, validation, and processing logic throughout the IC system.
/// Extensible to support additional source types for custom business scenarios.
/// </remarks>
enum 430 "IC Transaction Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// IC transaction originated from general journal entries or IC-specific journals.
    /// </summary>
    value(0; "Journal") { Caption = 'Journal'; }

    /// <summary>
    /// IC transaction originated from sales documents (orders, invoices, credit memos).
    /// </summary>
    value(1; "Sales Document") { Caption = 'Sales Document'; }

    /// <summary>
    /// IC transaction originated from purchase documents (orders, invoices, credit memos).
    /// </summary>
    value(2; "Purchase Document") { Caption = 'Purchase Document'; }
}
