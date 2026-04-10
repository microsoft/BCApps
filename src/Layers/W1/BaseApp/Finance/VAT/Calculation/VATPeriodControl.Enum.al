// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

/// <summary>
/// Defines control options for VAT period posting restrictions and validation.
/// Controls whether transactions can be posted within closed VAT periods and warning behavior.
/// </summary>
enum 260 "VAT Period Control"
{
    Extensible = false;

    /// <summary>
    /// Blocks posting within closed VAT periods and shows warning for released periods.
    /// Provides strict control over VAT period compliance with user notification.
    /// </summary>
    value(0; "Block posting within closed and warn for released period")
    {
        Caption = 'Block posting within closed and warn for released period';
    }
    /// <summary>
    /// Blocks posting within closed VAT periods without warnings for released periods.
    /// Enforces strict VAT period boundaries for closed periods only.
    /// </summary>
    value(1; "Block posting within closed period")
    {
        Caption = 'Block posting within closed period';
    }
    /// <summary>
    /// Shows warning when posting in closed VAT periods but allows posting to continue.
    /// Provides notification without blocking transaction processing.
    /// </summary>
    value(2; "Warn when posting in closed period")
    {
        Caption = 'Warn when posting in closed period';
    }
    /// <summary>
    /// Disables VAT period control completely, allowing posting in any period.
    /// No validation or warnings are provided for VAT period boundaries.
    /// </summary>
    value(3; "Disabled")
    {
        Caption = 'Disabled';
    }
}
