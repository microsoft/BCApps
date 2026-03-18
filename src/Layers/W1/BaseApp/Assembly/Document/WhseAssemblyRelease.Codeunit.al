// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 904 "Whse.-Assembly Release"
{

    trigger OnRun()
    begin
    end;

    var
        WarehouseRequest: Record "Warehouse Request";
        WhsePickRequest: Record "Whse. Pick Request";

    procedure Release(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        LocationOutput: Record Location;
        OldLocationCode: Code[10];
        First: Boolean;
    begin
        if AssemblyHeader."Location Code" <> '' then begin
            LocationOutput.SetLoadFields("Directed Put-away and Pick");
            if LocationOutput.Get(AssemblyHeader."Location Code") then
                if LocationOutput."Directed Put-away and Pick" then
                    AssemblyHeader.TestField("Unit of Measure Code");
        end;

        OldLocationCode := '';
        FilterAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        if AssemblyLine.Find('-') then begin
            First := true;
            repeat
                if First or (AssemblyLine."Location Code" <> OldLocationCode) then
                    CreateWarehouseRequest(AssemblyHeader, AssemblyLine);

                First := false;
                OldLocationCode := AssemblyLine."Location Code";
            until AssemblyLine.Next() = 0;
        end;

        WarehouseRequest.Reset();
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type);
        WarehouseRequest.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseRequest.SetRange("Source Subtype", AssemblyHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", AssemblyHeader."No.");
        WarehouseRequest.SetRange("Document Status", AssemblyHeader.Status::Open);
        WarehouseRequest.DeleteAll(true);
    end;

    procedure Reopen(AssemblyHeader: Record "Assembly Header")
    begin
        if AssemblyHeader."Document Type" = AssemblyHeader."Document Type"::Order then
            WarehouseRequest.Type := WarehouseRequest.Type::Outbound;

        WarehouseRequest.Reset();
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type);
        WarehouseRequest.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseRequest.SetRange("Source Subtype", AssemblyHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", AssemblyHeader."No.");
        WarehouseRequest.SetRange("Document Status", AssemblyHeader.Status::Released);
        WarehouseRequest.LockTable();
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("Document Status", WarehouseRequest."Document Status"::Open);

        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Assembly);
        WhsePickRequest.SetRange("Document No.", AssemblyHeader."No.");
        WhsePickRequest.SetRange(Status, AssemblyHeader.Status::Released);
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.ModifyAll(Status, WhsePickRequest.Status::Open);
    end;

    local procedure CreateWarehouseRequest(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    var
        AssemblyLine2: Record "Assembly Line";
        Location: Record Location;
    begin
        GetLocation(Location, AssemblyLine."Location Code");
        OnBeforeCreateWhseRqst(AssemblyHeader, AssemblyLine, Location);
        if Location."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"No Warehouse Handling" then
            exit;

        AssemblyLine2.Copy(AssemblyLine);
        AssemblyLine2.SetRange("Location Code", AssemblyLine."Location Code");
        AssemblyLine2.SetRange("Unit of Measure Code", '');
        if AssemblyLine2.FindFirst() then
            AssemblyLine2.TestField("Unit of Measure Code");

        case Location."Asm. Consump. Whse. Handling" of
            Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)",
            Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)":
                begin
                    WhsePickRequest.Init();
                    WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Assembly;
                    WhsePickRequest."Document Subtype" := AssemblyLine."Document Type".AsInteger();
                    WhsePickRequest."Document No." := AssemblyLine."Document No.";
                    WhsePickRequest.Status := WhsePickRequest.Status::Released;
                    WhsePickRequest."Location Code" := AssemblyLine."Location Code";
                    WhsePickRequest."Completely Picked" := AssemblyHeader.CompletelyPicked();
                    if WhsePickRequest."Completely Picked" and (not AssemblyLine.CompletelyPicked()) then
                        WhsePickRequest."Completely Picked" := false;
                    if not WhsePickRequest.Insert() then
                        WhsePickRequest.Modify();
                end;
            Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement":
                begin
                    WarehouseRequest.Init();
                    case AssemblyHeader."Document Type" of
                        AssemblyHeader."Document Type"::Order:
                            WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
                    end;
                    WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Assembly Consumption";
                    WarehouseRequest."Source Type" := DATABASE::"Assembly Line";
                    WarehouseRequest."Source Subtype" := AssemblyLine."Document Type".AsInteger();
                    WarehouseRequest."Source No." := AssemblyLine."Document No.";
                    WarehouseRequest."Document Status" := WarehouseRequest."Document Status"::Released;
                    WarehouseRequest."Location Code" := AssemblyLine."Location Code";
                    WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Item;
                    WarehouseRequest."Destination No." := AssemblyHeader."Item No.";
                    WarehouseRequest."Completely Handled" := AssemblyCompletelyHandled(AssemblyHeader, AssemblyLine."Location Code");
                    OnBeforeWhseRequestInsert(WarehouseRequest, AssemblyLine, AssemblyHeader);
                    if not WarehouseRequest.Insert() then
                        WarehouseRequest.Modify();
                end;
        end;
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if LocationCode = '' then begin
                Location.GetLocationSetup(LocationCode, Location);
                Location.Code := '';
            end else
                Location.Get(LocationCode);
    end;

    local procedure FilterAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyDocumentType: Enum "Assembly Document Type"; DocumentNo: Code[20])
    begin
        AssemblyLine.SetCurrentKey("Document Type", "Document No.", Type, "Location Code");
        AssemblyLine.SetRange("Document Type", AssemblyDocumentType);
        AssemblyLine.SetRange("Document No.", DocumentNo);
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
    end;

    local procedure AssemblyCompletelyHandled(AssemblyHeader: Record "Assembly Header"; LocationCode: Code[10]): Boolean
    var
        AssemblyLine: Record "Assembly Line";
    begin
        FilterAssemblyLine(AssemblyLine, AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyLine.SetRange("Location Code", LocationCode);
        AssemblyLine.SetFilter("Remaining Quantity", '<>0');
        exit(AssemblyLine.IsEmpty());
    end;

    procedure DeleteLine(AssemblyLine: Record "Assembly Line")
    var
        AssemblyLine2: Record "Assembly Line";
        Location: Record Location;
        KeepWarehouseRequest: Boolean;
    begin
        if AssemblyLine.Type <> AssemblyLine.Type::Item then
            exit;

        KeepWarehouseRequest := false;
        if Location.Get(AssemblyLine."Location Code") then;
        FilterAssemblyLine(AssemblyLine2, AssemblyLine."Document Type", AssemblyLine."Document No.");
        AssemblyLine2.SetFilter("Line No.", '<>%1', AssemblyLine."Line No.");
        AssemblyLine2.SetRange("Location Code", AssemblyLine."Location Code");
        AssemblyLine2.SetFilter("Remaining Quantity", '<>0');
        if AssemblyLine2.Find('-') then
            // Other lines for same location exist in the order.
            repeat
                if (not AssemblyLine2.CompletelyPicked()) or
                    (Location."Asm. Consump. Whse. Handling" <> Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)")
                then
                    KeepWarehouseRequest := true; // if lines are incompletely picked.
            until (AssemblyLine2.Next() = 0) or KeepWarehouseRequest;

        OnDeleteLineOnBeforeDeleteWhseRqst(AssemblyLine2, KeepWarehouseRequest);

        if not KeepWarehouseRequest then
            if Location."Asm. Consump. Whse. Handling" in [Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)"] then
                DeleteWhsePickRequest(AssemblyLine, false)
            else
                DeleteWarehouseRequest(AssemblyLine, false);
    end;

    local procedure DeleteWhsePickRequest(AssemblyLine: Record "Assembly Line"; DeleteAllWhsePickRequests: Boolean)
    begin
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Assembly);
        WhsePickRequest.SetRange("Document No.", AssemblyLine."Document No.");
        if not DeleteAllWhsePickRequests then begin
            WhsePickRequest.SetRange("Document Subtype", AssemblyLine."Document Type");
            WhsePickRequest.SetRange("Location Code", AssemblyLine."Location Code");
        end;
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.DeleteAll(true);
    end;

    local procedure DeleteWarehouseRequest(AssemblyLine: Record "Assembly Line"; DeleteAllWhseRqst: Boolean)
    var
        WarehouseRequest2: Record "Warehouse Request";
    begin
        if not DeleteAllWhseRqst then
            case true of
                AssemblyLine."Remaining Quantity" > 0:
                    WarehouseRequest2.SetRange(Type, WarehouseRequest2.Type::Outbound);
                AssemblyLine."Remaining Quantity" < 0:
                    WarehouseRequest2.SetRange(Type, WarehouseRequest2.Type::Inbound);
                AssemblyLine."Remaining Quantity" = 0:
                    exit;
            end;
        WarehouseRequest2.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseRequest2.SetRange("Source No.", AssemblyLine."Document No.");
        if not DeleteAllWhseRqst then begin
            WarehouseRequest2.SetRange("Source Subtype", AssemblyLine."Document Type");
            WarehouseRequest2.SetRange("Location Code", AssemblyLine."Location Code");
        end;
        if not WarehouseRequest2.IsEmpty() then
            WarehouseRequest2.DeleteAll(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRqst(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; var Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnBeforeDeleteWhseRqst(var AssemblyLine: Record "Assembly Line"; var KeepWhseRequest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseRequestInsert(var WarehouseRequest: Record "Warehouse Request"; AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header")
    begin
    end;
}

