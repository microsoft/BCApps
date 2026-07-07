// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 99000773 "Order Tracking Policy"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = 'None'; }
    value(1; "Tracking Only") { Caption = 'Tracking Only'; }
    value(2; "Tracking & Action Msg.") { Caption = 'Tracking & Action Msg.'; }
}
