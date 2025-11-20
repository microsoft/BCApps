// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

using Microsoft.Foundation.Reporting;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using System.Reflection;

table 7355 "Report Selection Warehouse"
{
    Caption = 'Report Selection Warehouse';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Usage; Enum "Report Selection Warehouse Usage")
        {
            Caption = 'Usage';
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
            trigger OnValidate()
            begin
                CalcFields("Report Caption");
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
    trigger OnInsert()
    begin
        if ("Report ID" <= 0) then
            Error(ReportIDErr);
    end;

    var
        ReportIDErr: Label 'You must specify a value in the Report ID field. It cannot be less than or equal to 0.';

    procedure NewRecord()
    var
        ReportSelectionWhse2: Record "Report Selection Warehouse";
    begin
        ReportSelectionWhse2.SetRange(Usage, Usage);
        if ReportSelectionWhse2.FindLast() and (ReportSelectionWhse2.Sequence <> '') then
            Sequence := IncStr(ReportSelectionWhse2.Sequence)
        else
            Sequence := '1';
    end;

    procedure PrintWhseActivityHeader(var WhseActivHeader: Record "Warehouse Activity Header"; ReportUsage: Enum "Report Selection Warehouse Usage"; HideDialog: Boolean)
    begin
        PrintDocuments(WhseActivHeader, ReportUsage, not HideDialog);
    end;

    procedure PrintWhseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; HideDialog: Boolean)
    begin
        PrintDocuments(WarehouseReceiptHeader, Usage::Receipt, not HideDialog);
    end;

    procedure PrintPostedWhseReceiptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; HideDialog: Boolean)
    begin
        PrintDocuments(PostedWhseReceiptHeader, Usage::"Posted Receipt", not HideDialog);
    end;

    procedure PrintWhseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; HideDialog: Boolean)
    begin
        PrintDocuments(WarehouseShipmentHeader, Usage::Shipment, not HideDialog);
    end;

    procedure PrintPostedWhseShipmentHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; HideDialog: Boolean)
    begin
        PrintDocuments(PostedWhseShipmentHeader, Usage::"Posted Shipment", not HideDialog);
    end;

    procedure PrintDocuments(RecVarToPrint: Variant; ReportUsage: Enum "Report Selection Warehouse Usage"; ShowRequestPage: Boolean)
    var
        TempReportSelectionWarehouse: Record "Report Selection Warehouse" temporary;
        IsHandled: Boolean;
    begin
        SelectTempReportSelectionsToPrint(TempReportSelectionWarehouse, ReportUsage);
        if TempReportSelectionWarehouse.FindSet() then
            repeat
                IsHandled := false;
                OnBeforePrintDocument(TempReportSelectionWarehouse, ShowRequestPage, RecVarToPrint, IsHandled);
                if not IsHandled then
                    Report.Run(TempReportSelectionWarehouse."Report ID", ShowRequestPage, false, RecVarToPrint);
                OnAfterPrintDocument(TempReportSelectionWarehouse, ShowRequestPage, RecVarToPrint);
            until TempReportSelectionWarehouse.Next() = 0;
    end;

    local procedure SelectTempReportSelectionsToPrint(var TempReportSelectionWarehouse: Record "Report Selection Warehouse"; ReportUsage: Enum "Report Selection Warehouse Usage")
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
        IsHandled: Boolean;
    begin
        SetRange(Usage, ReportUsage);
        if IsEmpty() then
            ReportSelectionMgt.InitReportSelectionWhse(Usage);

        OnSelectTempReportSelectionsToPrint(TempReportSelectionWarehouse, Rec, IsHandled);
        if IsHandled then
            exit;

        if FindSet() then
            repeat
                TempReportSelectionWarehouse := Rec;
                if TempReportSelectionWarehouse.Insert() then;
            until Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocument(TempReportSelectionWarehouse: Record "Report Selection Warehouse" temporary; ShowRequestPage: Boolean; RecVarToPrint: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintDocument(TempReportSelectionWarehouse: Record "Report Selection Warehouse" temporary; ShowRequestPage: Boolean; RecVarToPrint: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectTempReportSelectionsToPrint(var TempReportSelectionWarehouse: Record "Report Selection Warehouse" temporary; var FromReportSelectionWarehouse: Record "Report Selection Warehouse"; var IsHandled: Boolean)
    begin
    end;
}

