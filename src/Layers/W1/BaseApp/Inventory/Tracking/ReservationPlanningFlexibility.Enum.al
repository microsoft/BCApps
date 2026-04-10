// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

#pragma warning disable AL0659
enum 340 "Reservation Planning Flexibility"
#pragma warning restore AL0659
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Unlimited") { Caption = 'Unlimited'; }
    value(1; "None") { Caption = 'None'; }
}
