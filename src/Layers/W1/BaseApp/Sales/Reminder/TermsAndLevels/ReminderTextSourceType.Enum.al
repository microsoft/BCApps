// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Specifies whether reminder text is associated with a reminder term or a specific reminder level.
/// </summary>
enum 1890 "Reminder Text Source Type"
{
    Extensible = true;

    /// <summary>
    /// Indicates that the reminder text is associated with a reminder term configuration.
    /// </summary>
    value(0; "Reminder Term")
    {
        Caption = 'Reminder Term';
    }
    /// <summary>
    /// Indicates that the reminder text is associated with a specific reminder level within a term.
    /// </summary>
    value(1; "Reminder Level")
    {
        Caption = 'Reminder Level';
    }
}