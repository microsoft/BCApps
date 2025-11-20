// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.History;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

table 6507 "Item Entry Relation"
{
    Caption = 'Item Entry Relation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Entry No."; Integer)
        {
            Caption = 'Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(30; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(31; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
        }
    }

    keys
    {
        key(Key1; "Item Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Type", "Source Subtype", "Source Ref. No.", "Source Prod. Order Line", "Source Batch Name")
        {
        }
        key(Key3; "Order No.", "Order Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InitFromTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        Init();
        "Item Entry No." := TrackingSpecification."Entry No.";
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterInitFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromItemJnlLine(ItemJournalLine: Record "Item Journal Line")
    begin
        "Serial No." := ItemJournalLine."Serial No.";
        "Lot No." := ItemJournalLine."Lot No.";

        OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJournalLine);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure TransferFieldsSalesShptLine(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
        SetSource(DATABASE::"Sales Shipment Line", 0, SalesShipmentLine."Document No.", SalesShipmentLine."Line No.");
        SetOrderInfo(SalesShipmentLine."Order No.", SalesShipmentLine."Order Line No.");
    end;

    procedure TransferFieldsReturnRcptLine(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
        SetSource(DATABASE::"Return Receipt Line", 0, ReturnReceiptLine."Document No.", ReturnReceiptLine."Line No.");
        SetOrderInfo(ReturnReceiptLine."Return Order No.", ReturnReceiptLine."Return Order Line No.");
    end;

    procedure TransferFieldsPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        SetSource(DATABASE::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.", PurchRcptLine."Line No.");
        SetOrderInfo(PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
    end;

    procedure TransferFieldsReturnShptLine(var ReturnShipmentLine: Record "Return Shipment Line")
    begin
        SetSource(DATABASE::"Return Shipment Line", 0, ReturnShipmentLine."Document No.", ReturnShipmentLine."Line No.");
        SetOrderInfo(ReturnShipmentLine."Return Order No.", ReturnShipmentLine."Return Order Line No.");
    end;

    procedure TransferFieldsTransShptLine(var TransferShipmentLine: Record "Transfer Shipment Line")
    begin
        SetSource(DATABASE::"Transfer Shipment Line", 0, TransferShipmentLine."Document No.", TransferShipmentLine."Line No.");
        SetOrderInfo(TransferShipmentLine."Transfer Order No.", TransferShipmentLine."Line No.");
    end;

    procedure TransferFieldsTransRcptLine(var TransferReceiptLine: Record "Transfer Receipt Line")
    begin
        SetSource(DATABASE::"Transfer Receipt Line", 0, TransferReceiptLine."Document No.", TransferReceiptLine."Line No.");
        SetOrderInfo(TransferReceiptLine."Transfer Order No.", TransferReceiptLine."Line No.");
    end;

#if not CLEAN25
    [Obsolete('Moved to table Service Shipment Line', '25.0')]
    procedure TransferFieldsServShptLine(var ServiceShipmentLine: Record Microsoft.Service.History."Service Shipment Line")
    begin
        ServiceShipmentLine.TransferToItemEntryRelation(Rec);
    end;
#endif

    procedure TransferFieldsPostedAsmHeader(var PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
        SetSource(DATABASE::"Posted Assembly Header", 0, PostedAssemblyHeader."No.", 0);
        SetOrderInfo(PostedAssemblyHeader."Order No.", 0);
    end;

    procedure TransferFieldsPostedAsmLine(var PostedAssemblyLine: Record "Posted Assembly Line")
    begin
        SetSource(DATABASE::"Posted Assembly Line", 0, PostedAssemblyLine."Document No.", PostedAssemblyLine."Line No.");
        SetOrderInfo(PostedAssemblyLine."Order No.", PostedAssemblyLine."Order Line No.");
    end;

    procedure TransferFieldsInvtRcptLine(var InvtReceiptLine: Record "Invt. Receipt Line")
    begin
        SetSource(DATABASE::"Invt. Receipt Line", 0, InvtReceiptLine."Document No.", InvtReceiptLine."Line No.");
        SetSource2("Source Batch Name", 0);
    end;

    procedure TransferFieldsInvtShptLine(var InvtShipmentLine: Record "Invt. Shipment Line")
    begin
        SetSource(DATABASE::"Invt. Shipment Line", 0, InvtShipmentLine."Document No.", InvtShipmentLine."Line No.");
        SetSource2("Source Batch Name", 0);
    end;

    procedure TransferFieldsDirectTransLine(var DirectTransLine: Record "Direct Trans. Line")
    begin
        SetSource(DATABASE::"Direct Trans. Line", 0, DirectTransLine."Document No.", DirectTransLine."Line No.");
        SetOrderInfo(DirectTransLine."Transfer Order No.", DirectTransLine."Line No.");
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;

        OnAfterSetSource(Rec, "Source Type", "Source Subtype", "Source ID", "Source Ref. No.")
    end;

    procedure SetSource2(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;

        OnAfterSetSource2(Rec, "Source Batch Name", "Source Prod. Order Line")
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source Type", SourceType);
        SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceID, SourceRefNo, SourceKey);
    end;

    procedure SetSourceFilter2(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetOrderInfo(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        "Order No." := OrderNo;
        "Order Line No." := OrderLineNo;

        OnAfterSetOrderInfo(Rec, "Order No.", "Order Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTrackingSpec(var ItemEntryRelation: Record "Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var ItemEntryRelation: Record "Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemJnlLine(var ItemEntryRelation: Record "Item Entry Relation"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var ItemEntryRelation: Record "Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSource(ItemEntryRelation: Record "Item Entry Relation"; var SourceType: Integer; var SourceSubtype: Option; var SourceID: Code[20]; var SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSource2(ItemEntryRelation: Record "Item Entry Relation"; var SourceBatchName: Code[10]; var SourceProdOrderLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetOrderInfo(ItemEntryRelation: Record "Item Entry Relation"; var OrderNo: Code[20]; var OrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var ItemEntryRelation: Record "Item Entry Relation"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
    end;
}
