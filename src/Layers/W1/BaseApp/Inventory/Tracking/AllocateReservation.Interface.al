// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

interface "Allocate Reservation"
{
    procedure Allocate(var ReservationWkshLine: Record "Reservation Wksh. Line");

    procedure DeleteAllocation(var ReservationWkshLine: Record "Reservation Wksh. Line");

    procedure AllocationCompleted(var ReservationWkshLine: Record "Reservation Wksh. Line"): Boolean;

    procedure GetDescription(): Text;
}
