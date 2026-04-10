// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Defines the purpose of each line on a reminder document, such as reminder entry, text, or fee lines.
/// </summary>
enum 297 "Reminder Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Represents a standard reminder line for an overdue customer ledger entry.
    /// </summary>
    value(0; "Reminder Line") { Caption = 'Reminder Line'; }
    /// <summary>
    /// Represents a line for entries that are not yet due but are included for informational purposes.
    /// </summary>
    value(1; "Not Due") { Caption = 'Not Due'; }
    /// <summary>
    /// Represents introductory text that appears at the beginning of the reminder document.
    /// </summary>
    value(2; "Beginning Text") { Caption = 'Beginning Text'; }
    /// <summary>
    /// Represents closing text that appears at the end of the reminder document.
    /// </summary>
    value(3; "Ending Text") { Caption = 'Ending Text'; }
    /// <summary>
    /// Represents a rounding adjustment line used to round the reminder total amount.
    /// </summary>
    value(4; "Rounding") { Caption = 'Rounding'; }
    /// <summary>
    /// Represents a line for entries that are on hold and excluded from reminder calculations.
    /// </summary>
    value(5; "On Hold") { Caption = 'On Hold'; }
    /// <summary>
    /// Represents an additional fee charged at the reminder header level.
    /// </summary>
    value(6; "Additional Fee") { Caption = 'Additional Fee'; }
    /// <summary>
    /// Represents a fee charged per individual reminder line.
    /// </summary>
    value(7; "Line Fee") { Caption = 'Line Fee'; }

}
