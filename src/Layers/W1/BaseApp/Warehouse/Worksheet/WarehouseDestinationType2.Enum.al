// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

enum 7313 "Warehouse Destination Type 2"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "MovementWorksheet") { Caption = 'Movement Worksheet'; }
    value(1; "WhseInternalPutawayHeader") { Caption = 'Whse. Internal Putaway Header'; }
    value(2; "ItemJournalLine") { Caption = 'Item Journal Line'; }
    value(3; "TransferHeader") { Caption = 'Transfer Header'; }
    value(4; "InternalMovementHeader") { Caption = 'Internal Movement Header'; }
}
