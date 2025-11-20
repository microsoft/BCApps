// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 6483 "Serv. Item Tracking Mgt."
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnIsOrderNetworkEntity', '', false, false)]
    local procedure OnIsOrderNetworkEntity(Type: Integer; Subtype: Integer; var IsNetworkEntity: Boolean);
    begin
        if Type = Database::"Service Line" then
            IsNetworkEntity := (Subtype = 1);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnAfterItemTrkgTypeIsManagedByWhse', '', false, false)]
    local procedure OnAfterItemTrkgTypeIsManagedByWhse(Type: Integer; var TypeIsManagedByWhse: Boolean);
    begin
        if Type = Database::"Service Line" then
            TypeIsManagedByWhse := true;
    end;

    procedure CopyHandledItemTrkgToServLine(FromServLine: Record "Service Line"; ToServLine: Record "Service Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        // Used for combined shipment/returns:
        if FromServLine.Type <> FromServLine.Type::Item then
            exit;

        case ToServLine."Document Type" of
            ToServLine."Document Type"::Invoice:
                begin
                    ItemEntryRelation.SetSourceFilter(
                      Database::"Service Shipment Line", 0, ToServLine."Shipment No.", ToServLine."Shipment Line No.", true);
                    ItemEntryRelation.SetSourceFilter2('', 0);
                end;
            else
                ToServLine.FieldError("Document Type", Format(ToServLine."Document Type"));
        end;

        ItemTrackingManagement.InsertProspectReservEntryFromItemEntryRelationAndSourceData(
          ItemEntryRelation, ToServLine."Document Type".AsInteger(), ToServLine."Document No.", ToServLine."Line No.");
    end;
}
