// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

enum 299 "Reminder Comment Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Reminder") { Caption = 'Reminder'; }
    value(1; "Issued Reminder") { Caption = 'Issued Reminder'; }
}
