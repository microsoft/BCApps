// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

codeunit 10001 "Shipment Line - Edit"
{
    Permissions = TableData "Sales Shipment Line" = imd;
    TableNo = "Sales Shipment Line";

    trigger OnRun()
    begin
        SalesShipmentLine := Rec;
        SalesShipmentLine.LockTable();
        SalesShipmentLine.Find();
        SalesShipmentLine."Package Tracking No." := Rec."Package Tracking No.";
        SalesShipmentLine.Modify();
        Rec := SalesShipmentLine;

        OnAfterOnRun(Rec);
    end;

    var
        SalesShipmentLine: Record "Sales Shipment Line";

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;
}

