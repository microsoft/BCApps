// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Defines which currency amounts should be fixed during exchange rate adjustments.
/// Determines whether to fix the base currency amount, relational currency amount, or both.
/// </summary>
/// <remarks>
/// Used in currency exchange rate configurations to control adjustment behavior.
/// Extensible to support custom fixing strategies for specific business requirements.
/// </remarks>
enum 330 "Fix Exch. Rate Amount Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    /// <summary>
    /// Fix the base currency amount during exchange rate adjustments.
    /// </summary>
    value(0; "Currency") { Caption = 'Currency'; }
    /// <summary>
    /// Fix the relational currency amount during exchange rate adjustments.
    /// </summary>
    value(1; "Relational Currency") { Caption = 'Relational Currency'; }
    /// <summary>
    /// Fix both currency and relational currency amounts during adjustments.
    /// </summary>
    value(2; "Both") { Caption = 'Both'; }
}
