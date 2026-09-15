// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity.History;

using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Warehouse.Activity;

tableextension 99000771 "Mfg. Warehouse Activity Line" extends "Warehouse Activity Line"
{
    fields
    {
        modify("Destination No.")
        {
            TableRelation = if ("Destination Type" = const(Family)) Family;
        }
        modify("Whse. Document No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Production)) "Production Order"."No." where("No." = field("Whse. Document No."));
        }
        modify("Whse. Document Line No.")
        {
            TableRelation = if ("Whse. Document Type" = const(Production)) "Prod. Order Line"."Line No." where("Prod. Order No." = field("No."),
                                                                                                               "Line No." = field("Line No."));
        }
    }

    internal procedure CopyTrackingFromProdOrderLineTrackingBuffer(var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary)
    begin
        "Serial No." := TempProdOrdLineTrackingBuff."Serial No.";
        "Lot No." := TempProdOrdLineTrackingBuff."Lot No.";
        "Package No." := TempProdOrdLineTrackingBuff."Package No.";

        OnAfterCopyTrackingFromProdOrderLineTrackingBuffer(Rec, TempProdOrdLineTrackingBuff);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromProdOrderLineTrackingBuffer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff." temporary)
    begin
    end;
}