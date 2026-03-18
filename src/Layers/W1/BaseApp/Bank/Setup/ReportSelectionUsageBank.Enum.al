// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

/// <summary>
/// Defines report usage types for bank account reporting and document generation.
/// Supports extensibility for custom bank-related report categories.
/// </summary>
/// <remarks>
/// Used in report selection setup to categorize bank-specific reports and documents.
/// Extensible to support additional bank reporting scenarios and custom report types.
/// </remarks>
enum 385 "Report Selection Usage Bank"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Bank account statement reports for periodic account activity summaries.
    /// </summary>
    value(0; "Statement") { Caption = 'Statement'; }
    /// <summary>
    /// Test reports for bank reconciliation validation before posting.
    /// </summary>
    value(1; "Reconciliation - Test") { Caption = 'Reconciliation - Test'; }
    /// <summary>
    /// Check printing and check-related document reports.
    /// </summary>
    value(2; "Check") { Caption = 'Check'; }
    /// <summary>
    /// Reports for posted payment reconciliation transactions and audit trails.
    /// </summary>
    value(8; "Posted Payment Reconciliation") { Caption = 'Posted Payment Reconciliation'; }
}
