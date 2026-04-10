// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Defines recurring methods for general journal entries determining how recurring transactions are processed.
/// Controls the behavior of recurring journal entries including amount calculation and reversal logic.
/// </summary>
/// <remarks>
/// Recurring method options for automated journal entry processing in recurring journal templates.
/// Extensible enum supporting custom recurring methods via extensions for specialized business requirements.
/// Key methods: Fixed amounts, variable amounts, balance calculations, reversing entries, dimension-based balancing.
/// Usage: Applied to recurring journal templates to control periodic transaction generation behavior.
/// </remarks>
enum 53 "Gen. Journal Recurring Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Blank recurring method for one-time or non-recurring journal entries.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Fixed amount recurring method using the same amount for each recurring period.
    /// </summary>
    value(1; "F  Fixed") { Caption = 'F  Fixed'; }
    /// <summary>
    /// Variable amount recurring method allowing different amounts for each recurring period.
    /// </summary>
    value(2; "V  Variable") { Caption = 'V  Variable'; }
    /// <summary>
    /// Balance recurring method posting the account balance as the recurring amount.
    /// </summary>
    value(3; "B  Balance") { Caption = 'B  Balance'; }
    /// <summary>
    /// Reversing fixed method posting fixed amounts and automatic reversal entries.
    /// </summary>
    value(4; "RF Reversing Fixed") { Caption = 'RF Reversing Fixed'; }
    /// <summary>
    /// Reversing variable method posting variable amounts and automatic reversal entries.
    /// </summary>
    value(5; "RV Reversing Variable") { Caption = 'RV Reversing Variable'; }
    /// <summary>
    /// Reversing balance method posting account balance and automatic reversal entries.
    /// </summary>
    value(6; "RB Reversing Balance") { Caption = 'RB Reversing Balance'; }
    /// <summary>
    /// Balance by dimension method posting account balance calculated by dimension values.
    /// </summary>
    value(7; "BD Balance by Dimension") { Caption = 'BD Balance by Dimension'; }
    /// <summary>
    /// Reversing balance by dimension method with balance calculation by dimensions and automatic reversal.
    /// </summary>
    value(8; "RBD Reversing Balance by Dimension") { Caption = 'RBD Reversing Balance by Dimension'; }
}
