// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Service.History;
using Microsoft.Inventory.Ledger;

codeunit 6481 "Serv. Item Tracing Mgt."
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnSetRecordIDOnProcessServiceDocument', '', false, false)]
    local procedure OnSetRecordIDOnProcessServiceDocument(ItemLedgEntry: Record "Item Ledger Entry"; var TrackingEntry: Record "Item Tracing Buffer")
    var
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        RecRef: RecordRef;
    begin
        OnSetRecordIDOnBeforeProcessServiceDocument(ItemLedgEntry, TrackingEntry);

        case ItemLedgEntry."Document Type" of
            ItemLedgEntry."Document Type"::"Service Shipment":
                if ServShptHeader.Get(TrackingEntry."Document No.") then begin
                    RecRef.GetTable(ServShptHeader);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end else begin
                    RecRef.GetTable(ItemLedgEntry);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end;
            ItemLedgEntry."Document Type"::"Service Invoice":
                if ServInvHeader.Get(TrackingEntry."Document No.") then begin
                    RecRef.GetTable(ServInvHeader);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end else begin
                    RecRef.GetTable(ItemLedgEntry);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end;
            ItemLedgEntry."Document Type"::"Service Credit Memo":
                if ServCrMemoHeader.Get(TrackingEntry."Document No.") then begin
                    RecRef.GetTable(ServCrMemoHeader);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end else begin
                    RecRef.GetTable(ItemLedgEntry);
                    TrackingEntry."Record Identifier" := RecRef.RecordId;
                end;
        end
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetRecordIDOnBeforeProcessServiceDocument(ItemLedgEntry: Record "Item Ledger Entry"; var TrackingEntry: Record "Item Tracing Buffer")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(RecRef: RecordRef)
    var
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case RecRef.Number of
            Database::"Service Shipment Header":
                begin
                    RecRef.SetTable(ServShptHeader);
                    PAGE.RunModal(PAGE::"Posted Service Shipment", ServShptHeader);
                end;
            Database::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServInvHeader);
                    PAGE.RunModal(PAGE::"Posted Service Invoice", ServInvHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServCrMemoHeader);
                    PAGE.RunModal(PAGE::"Posted Service Credit Memo", ServCrMemoHeader);
                end;
        end;
    end;

}
