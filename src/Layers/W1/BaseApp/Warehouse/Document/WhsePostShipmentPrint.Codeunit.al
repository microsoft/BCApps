// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Finance.ReceivablesPayables;

codeunit 5765 "Whse.-Post Shipment + Print"
{
    TableNo = "Warehouse Shipment Line";

    trigger OnRun()
    begin
        WhseShptLine.Copy(Rec);
        Code();
        Rec := WhseShptLine;
    end;

    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        Selection: Integer;

    local procedure "Code"()
    var
        PostingSelectionManagement: Codeunit "Posting Selection Management";
        Invoice: Boolean;
        HideDialog: Boolean;
        IsPosted: Boolean;
    begin
        HideDialog := false;
        IsPosted := false;
        OnBeforeCode(WhseShptLine, HideDialog, Invoice, IsPosted, Selection);
        if IsPosted then
            exit;

        if WhseShptLine.Find() then
            if not HideDialog then begin
                if not PostingSelectionManagement.ConfirmPostWhseShipment(WhseShptLine, Selection) then
                    exit;
                Invoice := (Selection = 2);
            end;

        OnAfterConfirmPost(WhseShptLine, Invoice);

        WhsePostShipment.SetPostingSettings(Invoice);
        WhsePostShipment.SetPrint(true);
        OnCodeOnBeforePostShipmentLine(WhseShptLine, WhsePostShipment);
        WhsePostShipment.Run(WhseShptLine);
        WhsePostShipment.GetResultMessage();
        Clear(WhsePostShipment);
        OnAfterCode(WhseShptLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(WhseShipmentLine: Record "Warehouse Shipment Line"; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WhseShptLine: Record "Warehouse Shipment Line"; var HideDialog: Boolean; var Invoice: Boolean; var IsPosted: Boolean; var Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostShipmentLine(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WhsePostShipment: Codeunit "Whse.-Post Shipment")
    begin
    end;
}

