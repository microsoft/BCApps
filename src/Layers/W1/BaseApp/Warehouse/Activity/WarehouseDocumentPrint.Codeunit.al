// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Setup;

codeunit 5776 "Warehouse Document-Print"
{

    trigger OnRun()
    begin
    end;

    procedure PrintPickHeader(WhseActivHeader: Record "Warehouse Activity Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintPickHeader(WhseActivHeader, IsHandled);
        if IsHandled then
            exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Pick);
        WhseActivHeader.SetRange("No.", WhseActivHeader."No.");
        ReportSelectionWhse.PrintWhseActivityHeader(WhseActivHeader, ReportSelectionWhse.Usage::Pick, false);
    end;

    procedure PrintPutAwayHeader(WhseActivHeader: Record "Warehouse Activity Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintPutAwayHeader(WhseActivHeader, IsHandled);
        if IsHandled then
            exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Put-away");
        WhseActivHeader.SetRange("No.", WhseActivHeader."No.");
        ReportSelectionWhse.PrintWhseActivityHeader(WhseActivHeader, ReportSelectionWhse.Usage::"Put-away", false);
    end;

    procedure PrintMovementHeader(WhseActivHeader: Record "Warehouse Activity Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintMovementHeader(WhseActivHeader, IsHandled);
        if IsHandled then
            exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::Movement);
        WhseActivHeader.SetRange("No.", WhseActivHeader."No.");
        ReportSelectionWhse.PrintWhseActivityHeader(WhseActivHeader, ReportSelectionWhse.Usage::Movement, false);
    end;

    procedure PrintInvtPickHeader(WhseActivHeader: Record "Warehouse Activity Header"; HideDialog: Boolean)
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;

        OnBeforePrintInvtPickHeader(WhseActivHeader, IsHandled, HideDialog);
        if IsHandled then
            exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Invt. Pick");
        WhseActivHeader.SetRange("No.", WhseActivHeader."No.");
        ReportSelectionWhse.PrintWhseActivityHeader(WhseActivHeader, ReportSelectionWhse.Usage::"Invt. Pick", HideDialog);
    end;

    procedure PrintInvtPutAwayHeader(WhseActivHeader: Record "Warehouse Activity Header"; HideDialog: Boolean)
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintInvtPutAwayHeader(WhseActivHeader, IsHandled, HideDialog);
        if IsHandled then
            exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Invt. Put-away");
        WhseActivHeader.SetRange("No.", WhseActivHeader."No.");
        ReportSelectionWhse.PrintWhseActivityHeader(WhseActivHeader, ReportSelectionWhse.Usage::"Invt. Put-away", HideDialog);
    end;

    procedure PrintInvtMovementHeader(WhseActivHeader: Record "Warehouse Activity Header"; HideDialog: Boolean)
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintInvtMovementHeader(WhseActivHeader, IsHandled, HideDialog);
        if IsHandled then
            exit;

        WhseActivHeader.SetRange(Type, WhseActivHeader.Type::"Invt. Movement");
        WhseActivHeader.SetRange("No.", WhseActivHeader."No.");
        ReportSelectionWhse.PrintWhseActivityHeader(WhseActivHeader, ReportSelectionWhse.Usage::"Invt. Movement", HideDialog);
    end;

    procedure PrintRcptHeader(WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;

        OnBeforePrintRcptHeader(WarehouseReceiptHeader, IsHandled);
        if IsHandled then
            exit;

        WarehouseReceiptHeader.SetRange("No.", WarehouseReceiptHeader."No.");
        ReportSelectionWhse.PrintWhseReceiptHeader(WarehouseReceiptHeader, false);
    end;

    procedure PrintPostedRcptHeader(PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintPostedRcptHeader(PostedWhseReceiptHeader, IsHandled);
        if IsHandled then
            exit;

        PostedWhseReceiptHeader.SetRange("No.", PostedWhseReceiptHeader."No.");
        ReportSelectionWhse.PrintPostedWhseReceiptHeader(PostedWhseReceiptHeader, false);
    end;

    procedure PrintShptHeader(WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintShptHeader(WarehouseShipmentHeader, IsHandled);
        if IsHandled then
            exit;

        WarehouseShipmentHeader.SetRange("No.", WarehouseShipmentHeader."No.");
        ReportSelectionWhse.PrintWhseShipmentHeader(WarehouseShipmentHeader, false);
    end;

    procedure PrintPostedShptHeader(PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header")
    var
        ReportSelectionWhse: Record "Report Selection Warehouse";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintPostedShptHeader(PostedWhseShipmentHeader, IsHandled);
        if IsHandled then
            exit;

        PostedWhseShipmentHeader.SetRange("No.", PostedWhseShipmentHeader."No.");
        ReportSelectionWhse.PrintPostedWhseShipmentHeader(PostedWhseShipmentHeader, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPickHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPutAwayHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintMovementHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintInvtPickHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintInvtPutAwayHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintInvtMovementHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPostedRcptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPostedShptHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; var IsHandled: Boolean)
    begin
    end;
}

