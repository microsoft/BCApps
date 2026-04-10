// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

/// <summary>
/// Defines the source type for customer application calculations, determining how application amounts are derived.
/// </summary>
#pragma warning disable AL0659
enum 232 "Customer Apply Calculation Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the application amount is calculated directly from customer ledger entries.
    /// </summary>
    value(0; "Direct") { }
    /// <summary>
    /// Specifies that the application amount is calculated from a general journal line.
    /// </summary>
    value(1; "Gen. Jnl. Line") { }
    /// <summary>
    /// Specifies that the application amount is calculated from a sales header document.
    /// </summary>
    value(2; "Sales Header") { }
    /// <summary>
    /// Specifies that the application amount is calculated from a service header document.
    /// </summary>
    value(3; "Service Header") { }
}
