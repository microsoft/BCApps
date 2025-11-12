// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Foundation.Shipping;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;

codeunit 5781 "Whse. Validate Source Header"
{
    trigger OnRun()
    begin
    end;

    internal procedure ChangeWarehouseLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; ShipAdvice: Enum "Sales Header Shipping Advice")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WarehouseShipmentLine.Reset();
        WarehouseShipmentLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, false);
        if not WarehouseShipmentLine.IsEmpty() then
            WarehouseShipmentLine.ModifyAll("Shipping Advice", ShipAdvice);

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSublineNo, false);
        if not WarehouseActivityLine.IsEmpty() then
            WarehouseActivityLine.ModifyAll("Shipping Advice", ShipAdvice);

        WhseWorksheetLine.Reset();
        WhseWorksheetLine.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, false);
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.ModifyAll("Shipping Advice", ShipAdvice);
    end;
}

