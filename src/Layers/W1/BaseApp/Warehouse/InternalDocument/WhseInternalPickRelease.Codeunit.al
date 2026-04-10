// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 7315 "Whse. Internal Pick Release"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'There is nothing to release for %1 %2.';
#pragma warning restore AA0470
        Text001: Label 'You cannot reopen the whse. internal pick because warehouse worksheet lines exist that must first be handled or deleted.';
        Text002: Label 'You cannot reopen the whse. internal pick because warehouse activity lines exist that must first be handled or deleted.';
#pragma warning restore AA0074

    procedure Release(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    var
        Location: Record Location;
        WhsePickRequest: Record "Whse. Pick Request";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        if WhseInternalPickHeader.Status = WhseInternalPickHeader.Status::Released then
            exit;

        OnBeforeRelease(WhseInternalPickHeader);

        WhseInternalPickLine.SetRange("No.", WhseInternalPickHeader."No.");
        WhseInternalPickLine.SetFilter(Quantity, '<>0');
        if not WhseInternalPickLine.Find('-') then
            Error(Text000, WhseInternalPickHeader.TableCaption(), WhseInternalPickHeader."No.");

        if WhseInternalPickHeader."Location Code" <> '' then begin
            Location.Get(WhseInternalPickHeader."Location Code");
            Location.TestField("Require Pick");
        end else
            WhseInternalPickHeader.CheckPickRequired(WhseInternalPickHeader."Location Code");

        repeat
            WhseInternalPickLine.TestField("Item No.");
            WhseInternalPickLine.TestField("Unit of Measure Code");
            if Location."Directed Put-away and Pick" then
                WhseInternalPickLine.TestField("To Zone Code");
            if Location."Bin Mandatory" then
                WhseInternalPickLine.TestField("To Bin Code");
        until WhseInternalPickLine.Next() = 0;

        OnAfterTestWhsePickLine(WhseInternalPickHeader, WhseInternalPickLine);

        WhseInternalPickHeader.Status := WhseInternalPickHeader.Status::Released;
        WhseInternalPickHeader.Modify();

        OnAfterReleaseWarehousePick(WhseInternalPickHeader);

        CreateWhsePickRequest(WhseInternalPickHeader);

        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::"Internal Pick");
        WhsePickRequest.SetRange("Document No.", WhseInternalPickHeader."No.");
        WhsePickRequest.SetRange(Status, WhseInternalPickHeader.Status::Open);
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.DeleteAll(true);

        Commit();

        OnAfterRelease(WhseInternalPickHeader, WhseInternalPickLine);
    end;

    procedure Reopen(WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    var
        WhsePickRequest: Record "Whse. Pick Request";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        if WhseInternalPickHeader.Status = WhseInternalPickHeader.Status::Open then
            exit;

        IsHandled := false;
        OnBeforeReopen(WhseInternalPickHeader, IsHandled);
        if IsHandled then
            exit;

        PickWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        PickWkshLine.SetRange("Whse. Document Type", PickWkshLine."Whse. Document Type"::"Internal Pick");
        PickWkshLine.SetRange("Whse. Document No.", WhseInternalPickHeader."No.");
        if not PickWkshLine.IsEmpty() then
            Error(Text001);

        WhseActivLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WhseActivLine.SetRange("Whse. Document No.", WhseInternalPickHeader."No.");
        WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::"Internal Pick");
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        if not WhseActivLine.IsEmpty() then
            Error(Text002);

        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::"Internal Pick");
        WhsePickRequest.SetRange("Document No.", WhseInternalPickHeader."No.");
        WhsePickRequest.SetRange(Status, WhseInternalPickHeader.Status::Released);
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.ModifyAll(Status, WhsePickRequest.Status::Open);

        WhseInternalPickHeader.Status := WhseInternalPickHeader.Status::Open;
        WhseInternalPickHeader.Modify();

        OnAfterReopen(WhseInternalPickHeader);
    end;

    local procedure CreateWhsePickRequest(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    var
        WhsePickRequest: Record "Whse. Pick Request";
        Location: Record Location;
    begin
        if Location.RequirePicking(WhseInternalPickHeader."Location Code") then begin
            WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::"Internal Pick";
            WhsePickRequest."Document No." := WhseInternalPickHeader."No.";
            WhsePickRequest.Status := WhseInternalPickHeader.Status;
            WhsePickRequest."Location Code" := WhseInternalPickHeader."Location Code";
            WhsePickRequest."Zone Code" := WhseInternalPickHeader."To Zone Code";
            WhsePickRequest."Bin Code" := WhseInternalPickHeader."To Bin Code";
            WhseInternalPickHeader."Document Status" := WhseInternalPickHeader.GetDocumentStatus(0);
            WhsePickRequest."Completely Picked" :=
              WhseInternalPickHeader."Document Status" = WhseInternalPickHeader."Document Status"::"Completely Picked";
            if not WhsePickRequest.Insert() then
                WhsePickRequest.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestWhsePickLine(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseWarehousePick(var WhseInternalPickHeader: Record "Whse. Internal Pick Header")
    begin
    end;
}

