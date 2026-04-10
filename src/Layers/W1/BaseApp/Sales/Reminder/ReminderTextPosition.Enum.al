// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Specifies where reminder text appears on the document, such as beginning, ending, or email body.
/// </summary>
enum 298 "Reminder Text Position"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the text appears at the beginning of the reminder document.
    /// </summary>
    value(0; "Beginning") { Caption = 'Beginning'; }
    /// <summary>
    /// Specifies that the text appears at the end of the reminder document.
    /// </summary>
    value(1; "Ending") { Caption = 'Ending'; }
    /// <summary>
    /// Specifies that the text is used as the body content when the reminder is sent by email.
    /// </summary>
    value(2; "Email Body") { Caption = 'Email Body'; }
}
