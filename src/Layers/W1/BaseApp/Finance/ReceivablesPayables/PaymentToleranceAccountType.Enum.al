// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Defines account types for payment tolerance posting in receivables and payables transactions.
/// Used to specify whether tolerance amounts apply to customer or vendor account processing.
/// </summary>
/// <remarks>
/// Determines posting behavior for payment tolerance amounts in customer and vendor ledger operations.
/// Integrates with payment tolerance management for proper G/L account assignment.
/// Supports extensibility for additional account type classifications.
/// </remarks>
enum 426 "Payment Tolerance Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Customer account type for payment tolerance processing in receivables transactions.
    /// </summary>
    value(0; "Customer")
    {
        Caption = 'Customer';
    }
    /// <summary>
    /// Vendor account type for payment tolerance processing in payables transactions.
    /// </summary>
    value(1; "Vendor")
    {
        Caption = 'Vendor';
    }
}
