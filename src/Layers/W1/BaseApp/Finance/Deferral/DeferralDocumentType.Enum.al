// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Identifies the source document type that initiated a deferral schedule.
/// Used to differentiate handling logic for deferrals from different modules.
/// </summary>
enum 1702 "Deferral Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Deferral originates from a purchase document (order, invoice, credit memo).
    /// </summary>
    value(0; "Purchase") { Caption = 'Purchase'; }
    /// <summary>
    /// Deferral originates from a sales document (order, invoice, credit memo).
    /// </summary>
    value(1; "Sales") { Caption = 'Sales'; }
    /// <summary>
    /// Deferral originates from a general journal line entry.
    /// </summary>
    value(2; "G/L") { Caption = 'G/L'; }
}
