// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

codeunit 1406 "Return Shipment Header - Edit"
{
    Permissions = TableData "Return Shipment Header" = rm;
    TableNo = "Return Shipment Header";

    trigger OnRun()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader := Rec;
        ReturnShipmentHeader.LockTable();
        ReturnShipmentHeader.Find();
        ReturnShipmentHeader."Ship-to County" := Rec."Ship-to County";
        ReturnShipmentHeader."Ship-to Country/Region Code" := Rec."Ship-to Country/Region Code";
        OnBeforeReturnShipmentHeaderModify(ReturnShipmentHeader, Rec);
        ReturnShipmentHeader.TestField("No.", Rec."No.");
        ReturnShipmentHeader.Modify();
        Rec := ReturnShipmentHeader;

        OnRunOnAfterReturnShipmentHeaderEdit(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnShipmentHeaderModify(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnShipmentHeaderRec: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterReturnShipmentHeaderEdit(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;
}

