// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 6482 "Serv. Item Tracking Doc. Mgt."
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Doc. Management", 'OnRetrieveDocumentItemTracking', '', false, false)]
    local procedure OnRetrieveDocumentItemTracking(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; var sender: Codeunit "Item Tracking Doc. Management"; var Found: Boolean)
    begin
        case SourceType of
            Database::"Service Header":
                begin
                    RetrieveTrackingService(TempTrackingSpecBuffer, sender, SourceID, SourceSubType);
                    Found := true;
                end;
            Database::"Service Shipment Header":
                begin
                    RetrieveTrackingServiceShipment(TempTrackingSpecBuffer, sender, SourceID);
                    Found := true;
                end;
            Database::"Service Invoice Header":
                begin
                    RetrieveTrackingServiceInvoice(TempTrackingSpecBuffer, sender, SourceID);
                    Found := true;
                end;
        end;
    end;

    local procedure RetrieveTrackingService(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; var sender: Codeunit "Item Tracking Doc. Management"; SourceID: Code[20]; SourceSubType: Option)
    var
        ServLine: Record "Service Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        ServLine.SetRange("Document Type", SourceSubType);
        ServLine.SetRange("Document No.", SourceID);
        if not ServLine.IsEmpty() then begin
            ServLine.FindSet();
            repeat
                if (ServLine.Type = ServLine.Type::Item) and
                   (ServLine."No." <> '') and
                   (ServLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(ServLine."No.") then
                        Descr := Item.Description;
                    sender.FindReservEntries(
                        TempTrackingSpecBuffer, Database::"Service Line", ServLine."Document Type".AsInteger(),
                        ServLine."Document No.", '', 0, ServLine."Line No.", Descr);
                    sender.FindTrackingEntries(
                        TempTrackingSpecBuffer, Database::"Service Line", ServLine."Document Type".AsInteger(),
                        ServLine."Document No.", '', 0, ServLine."Line No.", Descr);
                end;
            until ServLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingServiceShipment(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; var sender: Codeunit "Item Tracking Doc. Management"; SourceID: Code[20])
    var
        ServShptLine: Record "Service Shipment Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        ServShptLine.SetRange("Document No.", SourceID);
        if not ServShptLine.IsEmpty() then begin
            ServShptLine.FindSet();
            repeat
                if (ServShptLine.Type = ServShptLine.Type::Item) and
                   (ServShptLine."No." <> '') and
                   (ServShptLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(ServShptLine."No.") then
                        Descr := Item.Description;
                    sender.FindShptRcptEntries(TempTrackingSpecBuffer,
                      Database::"Service Shipment Line", 0, ServShptLine."Document No.", '', 0, ServShptLine."Line No.", Descr);
                end;
            until ServShptLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingServiceInvoice(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; var sender: Codeunit "Item Tracking Doc. Management"; SourceID: Code[20])
    var
        ServInvLine: Record "Service Invoice Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        ServInvLine.SetRange("Document No.", SourceID);
        if not ServInvLine.IsEmpty() then begin
            ServInvLine.FindSet();
            repeat
                if (ServInvLine.Type = ServInvLine.Type::Item) and
                   (ServInvLine."No." <> '') and
                   (ServInvLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(ServInvLine."No.") then
                        Descr := Item.Description;
                    sender.FindInvoiceEntries(TempTrackingSpecBuffer,
                      Database::"Service Invoice Line", 0, ServInvLine."Document No.", '', 0, ServInvLine."Line No.", Descr);
                end;
            until ServInvLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Doc. Management", 'OnAfterTableSignFactor', '', false, false)]
    local procedure OnAfterTableSignFactor(TableNo: Integer; var Sign: Integer)
    begin
        if TableNo in [
                       Database::"Service Line",
                       Database::"Service Shipment Line",
                       Database::"Service Invoice Line"]
        then
            Sign := -1;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnAfterGetInvoiceSource', '', false, false)]
    local procedure OnAfterGetInvoiceSource(TrackingSpecification: Record "Tracking Specification"; var QtyToInvoiceColumnIsHidden: Boolean)
    begin
        if not QtyToInvoiceColumnIsHidden then
            QtyToInvoiceColumnIsHidden :=
                ((TrackingSpecification."Source Type" = Database::"Service Line") and
                (TrackingSpecification."Source Subtype" in [0, 2, 3, 4]));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnAfterGetHandleSource', '', false, false)]
    local procedure OnAferGetHandleSource(TrackingSpecification: Record "Tracking Specification"; var QtyToHandleColumnIsHidden: Boolean)
    begin
        if not QtyToHandleColumnIsHidden then
            QtyToHandleColumnIsHidden :=
                ((TrackingSpecification."Source Type" = Database::"Service Line") and
                (TrackingSpecification."Source Subtype" in [0, 2, 3]));
    end;
}
