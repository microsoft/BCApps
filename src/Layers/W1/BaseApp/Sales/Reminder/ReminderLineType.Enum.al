// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

enum 297 "Reminder Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Reminder Line") { Caption = 'Reminder Line'; }
    value(1; "Not Due") { Caption = 'Not Due'; }
    value(2; "Beginning Text") { Caption = 'Beginning Text'; }
    value(3; "Ending Text") { Caption = 'Ending Text'; }
    value(4; "Rounding") { Caption = 'Rounding'; }
    value(5; "On Hold") { Caption = 'On Hold'; }
    value(6; "Additional Fee") { Caption = 'Additional Fee'; }
    value(7; "Line Fee") { Caption = 'Line Fee'; }

}
