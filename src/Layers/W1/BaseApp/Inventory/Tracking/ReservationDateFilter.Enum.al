// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 520 "Reservation Date Filter"
{
    AssignmentCompatibility = true;

    value(0; "Shipment Date") { Caption = 'Shipment Date'; }
    value(1; "Expected Receipt Date") { Caption = 'Expected Receipt Date'; }
}
