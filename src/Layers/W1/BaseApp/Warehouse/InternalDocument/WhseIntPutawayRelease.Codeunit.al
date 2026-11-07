// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 7316 "Whse. Int. Put-away Release"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'There is nothing to release for %1 %2.';
#pragma warning restore AA0470
        Text001: Label 'You cannot reopen the whse. internal put-away because warehouse worksheet lines exist that must first be handled or deleted.';
        Text002: Label 'You cannot reopen the whse. internal put-away because warehouse activity lines exist that must first be handled or deleted.';
#pragma warning restore AA0074

    procedure Release(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header")
    var
        Location: Record Location;
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhseInternalPutawayLine: Record "Whse. Internal Put-away Line";
        SuppressCommit: Boolean;
    begin
        if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Released then
            exit;

        WhseInternalPutawayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        WhseInternalPutawayLine.SetFilter(Quantity, '<>0');
        if not WhseInternalPutawayLine.Find('-') then
            Error(Text000, WhseInternalPutAwayHeader.TableCaption(), WhseInternalPutAwayHeader."No.");

        if WhseInternalPutAwayHeader."Location Code" <> '' then begin
            Location.Get(WhseInternalPutAwayHeader."Location Code");
            Location.TestField("Require Put-away");
        end else
            WhseInternalPutAwayHeader.CheckPutawayRequired(WhseInternalPutAwayHeader."Location Code");

        repeat
            WhseInternalPutawayLine.TestField("Item No.");
            WhseInternalPutawayLine.TestField("Unit of Measure Code");
            if Location."Directed Put-away and Pick" then
                WhseInternalPutawayLine.TestField("From Zone Code");
            if Location."Bin Mandatory" then
                WhseInternalPutawayLine.TestField("From Bin Code");
        until WhseInternalPutawayLine.Next() = 0;

        WhseInternalPutAwayHeader.Status := WhseInternalPutAwayHeader.Status::Released;
        WhseInternalPutAwayHeader.Modify();

        CreateWhsePutAwayRequest(WhseInternalPutAwayHeader);

        WhsePutAwayRequest.SetRange(
          "Document Type", WhsePutAwayRequest."Document Type"::"Internal Put-away");
        WhsePutAwayRequest.SetRange("Document No.", WhseInternalPutAwayHeader."No.");
        WhsePutAwayRequest.SetRange(Status, WhseInternalPutAwayHeader.Status::Open);
        WhsePutAwayRequest.DeleteAll(true);

        OnReleaseOnBeforeCommit(WhseInternalPutAwayHeader, SuppressCommit);
        if not SuppressCommit then
            Commit();
    end;

    procedure Reopen(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header")
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Open then
            exit;

        WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        WhseWkshLine.SetRange("Whse. Document Type", WhseWkshLine."Whse. Document Type"::"Internal Put-away");
        WhseWkshLine.SetRange("Whse. Document No.", WhseInternalPutAwayHeader."No.");
        if not WhseWkshLine.IsEmpty() then
            Error(Text001);

        WhseActivLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WhseActivLine.SetRange("Whse. Document No.", WhseInternalPutAwayHeader."No.");
        WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::"Internal Put-away");
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Put-away");
        OnReopenOnBeforeWhseActivLineIsEmpty(WhseInternalPutAwayHeader, WhseActivLine);
        if not WhseActivLine.IsEmpty() then
            Error(Text002);

        WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::"Internal Put-away");
        WhsePutAwayRequest.SetRange("Document No.", WhseInternalPutAwayHeader."No.");
        WhsePutAwayRequest.SetRange(Status, WhseInternalPutAwayHeader.Status::Released);
        if WhsePutAwayRequest.Find('-') then
            repeat
                WhsePutAwayRequest.Status := WhseInternalPutAwayHeader.Status::Open;
                WhsePutAwayRequest.Modify();
            until WhsePutAwayRequest.Next() = 0;

        WhseInternalPutAwayHeader.Status := WhseInternalPutAwayHeader.Status::Open;
        WhseInternalPutAwayHeader.Modify();
    end;

    local procedure CreateWhsePutAwayRequest(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header")
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
    begin
        WhsePutAwayRequest."Document Type" := WhsePutAwayRequest."Document Type"::"Internal Put-away";
        WhsePutAwayRequest."Document No." := WhseInternalPutAwayHeader."No.";
        WhsePutAwayRequest.Status := WhseInternalPutAwayHeader.Status;
        WhsePutAwayRequest."Location Code" := WhseInternalPutAwayHeader."Location Code";
        WhsePutAwayRequest."Zone Code" := WhseInternalPutAwayHeader."From Zone Code";
        WhsePutAwayRequest."Bin Code" := WhseInternalPutAwayHeader."From Bin Code";
        WhseInternalPutAwayHeader."Document Status" := WhseInternalPutAwayHeader.GetDocumentStatus(0);
        WhsePutAwayRequest."Completely Put Away" :=
          WhseInternalPutAwayHeader."Document Status" = WhseInternalPutAwayHeader."Document Status"::"Completely Put Away";
        if not WhsePutAwayRequest.Insert() then
            WhsePutAwayRequest.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenOnBeforeWhseActivLineIsEmpty(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnBeforeCommit(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var SuppressCommit: Boolean)
    begin
    end;
}

