// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

enum 298 "Reminder Text Position"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Beginning") { Caption = 'Beginning'; }
    value(1; "Ending") { Caption = 'Ending'; }
    value(2; "Email Body") { Caption = 'Email Body'; }
}
