// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

#pragma warning disable AL0659
enum 524 "Report Selection Usage Reminder"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the report selection is used for reminder documents.
    /// </summary>
    value(0; "Reminder") { Caption = 'Reminder'; }
    /// <summary>
    /// Specifies that the report selection is used for finance charge memo documents.
    /// </summary>
    value(1; "Fin. Charge") { Caption = 'Fin. Charge'; }
    /// <summary>
    /// Specifies that the report selection is used for reminder test reports.
    /// </summary>
    value(2; "Reminder Test") { Caption = 'Reminder Test'; }
    /// <summary>
    /// Specifies that the report selection is used for finance charge memo test reports.
    /// </summary>
    value(3; "Fin. Charge Test") { Caption = 'Fin. Charge Test'; }
}
