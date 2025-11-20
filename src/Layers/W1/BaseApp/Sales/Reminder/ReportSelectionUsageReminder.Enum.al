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

    value(0; "Reminder") { Caption = 'Reminder'; }
    value(1; "Fin. Charge") { Caption = 'Fin. Charge'; }
    value(2; "Reminder Test") { Caption = 'Reminder Test'; }
    value(3; "Fin. Charge Test") { Caption = 'Fin. Charge Test'; }
}
