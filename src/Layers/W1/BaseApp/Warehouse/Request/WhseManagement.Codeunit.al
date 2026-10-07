// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;

codeunit 5775 "Whse. Management"
{

    trigger OnRun()
    begin
    end;

    var
        SourceDocumentNotDefinedErr: Label 'The Source Document is not defined.';
        SourceDocumentDoesNotExistErr: Label 'The %1 does not exist. Filters: %2.', Comment = '%1 = Table caption; %2 = filters';

    procedure GetWhseActivSourceDocument(SourceType: Integer; SourceSubtype: Integer): Enum "Warehouse Activity Source Document"
    begin
        exit(GetSourceDocumentType(SourceType, SourceSubtype));
    end;

    procedure GetWhseJnlSourceDocument(SourceType: Integer; SourceSubtype: Integer) SourceDocument: Enum "Warehouse Journal Source Document"
    begin
        exit(GetSourceDocumentType(SourceType, SourceSubtype));
    end;

    procedure GetWhseRqstSourceDocument(SourceType: Integer; SourceSubtype: Integer) SourceDocument: Enum "Warehouse Request Source Document"
    var
        WhseJournalSourceDocument: Enum "Warehouse Journal Source Document";
    begin
        WhseJournalSourceDocument := GetSourceDocumentType(SourceType, SourceSubtype);
        case WhseJournalSourceDocument of
            WhseJournalSourceDocument::"S. Order":
                SourceDocument := "Warehouse Request Source Document"::"Sales Order";
            WhseJournalSourceDocument::"S. Return Order":
                SourceDocument := "Warehouse Request Source Document"::"Sales Return Order";
            WhseJournalSourceDocument::"P. Order":
                SourceDocument := "Warehouse Request Source Document"::"Purchase Order";
            WhseJournalSourceDocument::"P. Return Order":
                SourceDocument := "Warehouse Request Source Document"::"Purchase Return Order";
            WhseJournalSourceDocument::"Inb. Transfer":
                SourceDocument := "Warehouse Request Source Document"::"Inbound Transfer";
            WhseJournalSourceDocument::"Outb. Transfer":
                SourceDocument := "Warehouse Request Source Document"::"Outbound Transfer";
            WhseJournalSourceDocument::"Assembly Order":
                SourceDocument := "Warehouse Request Source Document"::"Assembly Order";
            WhseJournalSourceDocument::"Assembly Consumption":
                SourceDocument := "Warehouse Request Source Document"::"Assembly Consumption";
            WhseJournalSourceDocument::"Job Usage":
                SourceDocument := "Warehouse Request Source Document"::"Job Usage";
            else
                SourceDocument := WhseJournalSourceDocument;
        end;

        OnAfterGetWhseRqstSourceDocument(WhseJournalSourceDocument, SourceDocument);
    end;

    procedure GetSourceDocumentType(SourceType: Integer; SourceSubtype: Integer): Enum "Warehouse Journal Source Document"
    var
        SourceDocumentType: Enum "Warehouse Journal Source Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocumentType(SourceType, SourceSubtype, SourceDocumentType, IsHandled);
        if IsHandled then
            exit(SourceDocumentType);

        case SourceType of
            Database::"Item Journal Line":
                case SourceSubtype of
                    0:
                        exit("Warehouse Journal Source Document"::"Item Jnl.");
                    1:
                        exit("Warehouse Journal Source Document"::"Reclass. Jnl.");
                    2:
                        exit("Warehouse Journal Source Document"::"Phys. Invt. Jnl.");
                    4:
                        exit("Warehouse Journal Source Document"::"Consumption Jnl.");
                    5:
                        exit("Warehouse Journal Source Document"::"Output Jnl.");
                end;
        end;

        IsHandled := false;
        OnAfterGetSourceDocumentType(SourceType, SourceSubtype, SourceDocumentType, IsHandled);
        if IsHandled then
            exit(SourceDocumentType);

        Error(SourceDocumentNotDefinedErr);
    end;

    procedure GetSourceDocument(SourceType: Integer; SourceSubtype: Integer): Integer
    begin
        exit(GetSourceDocumentType(SourceType, SourceSubtype).AsInteger());
    end;

    procedure GetJournalSourceDocument(SourceType: Integer; SourceSubtype: Integer) SourceDocument: Enum "Warehouse Journal Source Document"
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJournalSourceDocument(SourceType, SourceSubtype, SourceDocument, IsHandled);
        if IsHandled then
            exit(SourceDocument);

        case SourceType of
            Database::"Item Journal Line":
                case SourceSubtype of
                    0:
                        exit(SourceDocument::"Item Jnl.");
                    1:
                        exit(SourceDocument::"Reclass. Jnl.");
                    2:
                        exit(SourceDocument::"Phys. Invt. Jnl.");
                    4:
                        exit(SourceDocument::"Consumption Jnl.");
                    5:
                        exit(SourceDocument::"Output Jnl.");
                end;
        end;
        OnAfterGetJournalSourceDocument(SourceType, SourceSubtype, SourceDocument, IsHandled);
        if IsHandled then
            exit(SourceDocument);
        Error(SourceDocumentNotDefinedErr);
    end;

    procedure GetSourceType(WhseWkshLine: Record "Whse. Worksheet Line") SourceType: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceType(WhseWkshLine, SourceType, IsHandled);
        if IsHandled then
            exit(SourceType);

        case WhseWkshLine."Whse. Document Type" of
            WhseWkshLine."Whse. Document Type"::Receipt:
                SourceType := Database::"Posted Whse. Receipt Line";
            WhseWkshLine."Whse. Document Type"::Shipment:
                SourceType := Database::"Warehouse Shipment Line";
            WhseWkshLine."Whse. Document Type"::"Internal Put-away":
                SourceType := Database::"Whse. Internal Put-away Line";
            WhseWkshLine."Whse. Document Type"::"Internal Pick":
                SourceType := Database::"Whse. Internal Pick Line";
        end;
    end;

    procedure GetOutboundDocLineQtyOtsdg(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var QtyOutstanding: Decimal; var QtyBaseOutstanding: Decimal)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetCurrentKey("Source Type");
        WhseShptLine.SetRange("Source Type", SourceType);
        WhseShptLine.SetRange("Source Subtype", SourceSubType);
        WhseShptLine.SetRange("Source No.", SourceNo);
        WhseShptLine.SetRange("Source Line No.", SourceLineNo);
        if WhseShptLine.FindFirst() then begin
            WhseShptLine.CalcFields(WhseShptLine."Pick Qty. (Base)", WhseShptLine."Pick Qty.");
            WhseShptLine.CalcSums(WhseShptLine.Quantity, WhseShptLine."Qty. (Base)");
            QtyOutstanding := WhseShptLine.Quantity - WhseShptLine."Pick Qty." - WhseShptLine."Qty. Picked";
            QtyBaseOutstanding := WhseShptLine."Qty. (Base)" - WhseShptLine."Pick Qty. (Base)" - WhseShptLine."Qty. Picked (Base)";
        end else
            GetSrcDocLineQtyOutstanding(SourceType, SourceSubType, SourceNo,
              SourceLineNo, SourceSubLineNo, QtyOutstanding, QtyBaseOutstanding);
    end;

    local procedure GetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var QtyOutstanding: Decimal; var QtyBaseOutstanding: Decimal)
    begin
        QtyOutstanding := 0;
        QtyBaseOutstanding := 0;

        OnAfterGetSrcDocLineQtyOutstanding(SourceType, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, QtyOutstanding, QtyBaseOutstanding);
    end;

    procedure SetSourceFilterForWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            WarehouseReceiptLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseReceiptLine.SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            WarehouseReceiptLine.SetRange("Source Subtype", SourceSubType);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            WarehouseReceiptLine.SetRange("Source Line No.", SourceLineNo);

        OnAfterSetSourceFilterForWhseRcptLine(WarehouseReceiptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SetKey);
    end;

    procedure SetSourceFilterForWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            WarehouseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            WarehouseActivityLine.SetRange("Source Subtype", SourceSubType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            WarehouseActivityLine.SetRange("Source Line No.", SourceLineNo);
    end;

    procedure SetSourceFilterForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            WarehouseShipmentLine.SetRange("Source Subtype", SourceSubType);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            WarehouseShipmentLine.SetRange("Source Line No.", SourceLineNo);

        OnAfterSetSourceFilterForWhseShptLine(WarehouseShipmentLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SetKey);
    end;

    procedure SetSourceFilterForPostedWhseRcptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            PostedWhseReceiptLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        PostedWhseReceiptLine.SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            PostedWhseReceiptLine.SetRange("Source Subtype", SourceSubType);
        PostedWhseReceiptLine.SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            PostedWhseReceiptLine.SetRange("Source Line No.", SourceLineNo);

        OnAfterSetSourceFilterForPostedWhseRcptLine(PostedWhseReceiptLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SetKey);
    end;

    procedure SetSourceFilterForPostedWhseShptLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            PostedWhseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        PostedWhseShipmentLine.SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            PostedWhseShipmentLine.SetRange("Source Subtype", SourceSubType);
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            PostedWhseShipmentLine.SetRange("Source Line No.", SourceLineNo);

        OnAfterSetSourceFilterForPostedWhseShptLine(PostedWhseShipmentLine, SourceType, SourceSubType, SourceNo, SourceLineNo, SetKey);
    end;

    procedure GetSourceDocumentDoesNotExistErr(): Text;
    begin
        exit(SourceDocumentDoesNotExistErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var QtyOutstanding: Decimal; var QtyBaseOutstanding: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceDocumentType(SourceType: Integer; SourceSubtype: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocumentType(SourceType: Integer; SourceSubtype: Integer; var SourceDocumentType: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceType(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetJournalSourceDocument(SourceType: Integer; SourceSubtype: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilterForWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilterForWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilterForPostedWhseRcptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilterForPostedWhseShptLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetJournalSourceDocument(SourceType: Integer; SourceSubtype: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseRqstSourceDocument(WhseJournalSourceDocument: Enum "Warehouse Journal Source Document"; var SourceDocument: Enum "Warehouse Request Source Document")
    begin
    end;
}

