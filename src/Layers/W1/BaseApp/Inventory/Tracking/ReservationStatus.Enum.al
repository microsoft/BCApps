// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 337 "Reservation Status"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Reservation") { Caption = 'Reservation'; }
    value(1; "Tracking") { Caption = 'Tracking'; }
    value(2; "Surplus") { Caption = 'Surplus'; }
    value(3; "Prospect") { Caption = 'Prospect'; }
}
