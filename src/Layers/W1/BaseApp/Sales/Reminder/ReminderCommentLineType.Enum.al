// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Specifies the type of document that a reminder comment is associated with.
/// </summary>
enum 299 "Reminder Comment Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Indicates that the comment is associated with a draft reminder document.
    /// </summary>
    value(0; "Reminder") { Caption = 'Reminder'; }
    /// <summary>
    /// Indicates that the comment is associated with an issued reminder document.
    /// </summary>
    value(1; "Issued Reminder") { Caption = 'Issued Reminder'; }
}
