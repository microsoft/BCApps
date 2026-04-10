// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Defines the type of exchange rate adjustment to apply when processing currency revaluations.
/// Controls how amounts are adjusted during exchange rate adjustment procedures.
/// </summary>
/// <remarks>
/// Used throughout the exchange rate adjustment process to determine adjustment behavior.
/// Extensible to support custom adjustment strategies for specific business requirements.
/// </remarks>
enum 595 "Exch. Rate Adjustment Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// No exchange rate adjustment will be performed.
    /// </summary>
    value(0; "No Adjustment") { Caption = 'No Adjustment'; }
    /// <summary>
    /// Adjust the standard amount based on exchange rate changes.
    /// </summary>
    value(1; "Adjust Amount") { Caption = 'Adjust Amount'; }
    /// <summary>
    /// Adjust the additional currency amount based on exchange rate changes.
    /// </summary>
    value(2; "Adjust Additional-Currency Amount") { Caption = 'Adjust Additional-Currency Amount'; }
}
