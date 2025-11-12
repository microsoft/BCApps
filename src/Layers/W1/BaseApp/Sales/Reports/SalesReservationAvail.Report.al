// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Document;

report 209 "Sales Reservation Avail."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/SalesReservationAvail.rdlc';
    ApplicationArea = Reservation;
    Caption = 'Sales Reservation Avail.';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Sales Line"; "Sales Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where(Type = const(Item));
            RequestFilterFields = "Document Type", "Document No.", "No.", "Location Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(StrsubstnoDocTypeDocNo; StrSubstNo('%1 %2', "Document Type", "Document No."))
            {
            }
            column(ShowSalesLineGrHeader2; ShowSalesLineGrHeader2)
            {
            }
            column(No_SalesLine; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_SalesLine; Description)
            {
                IncludeCaption = true;
            }
            column(ShpmtDt__SalesLine; Format("Shipment Date"))
            {
            }
            column(Reserve__SalesLine; Reserve)
            {
                IncludeCaption = true;
            }
            column(OutstdngQtyBase_SalesLine; "Outstanding Qty. (Base)")
            {
                IncludeCaption = true;
            }
            column(ResrvdQtyBase_SalesLine; "Reserved Qty. (Base)")
            {
                IncludeCaption = true;
            }
            column(LineStatus; LineStatus)
            {
                OptionCaption = ' ,Shipped,Full Shipment,Partial Shipment,No Shipment';
            }
            column(LineReceiptDate; Format(LineReceiptDate))
            {
            }
            column(LineQuantityOnHand; LineQuantityOnHand)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ShowSalesLineBody; ShowSalesLines)
            {
            }
            column(DocumentReceiptDate; Format(DocumentReceiptDate))
            {
            }
            column(DocumentStatus; DocumentStatus)
            {
                OptionCaption = ' ,Shipped,Full Shipment,Partial Shipment,No Shipment';
            }
            column(ShipmentDt_SalesHeader; Format(SalesHeader."Shipment Date"))
            {
            }
            column(Reserve_SalesHeader; StrSubstNo('%1', SalesHeader.Reserve))
            {
            }
            column(DocType__SalesLine; "Document Type")
            {
            }
            column(DoctNo_SalesLine; "Document No.")
            {
            }
            column(LineNo_SalesLine; "Line No.")
            {
            }
            column(SalesResrvtnAvalbtyCaption; SalesResrvtnAvalbtyCaptionLbl)
            {
            }
            column(CurrRepPageNoCaption; CurrRepPageNoCaptionLbl)
            {
            }
            column(SalesLineShpmtDtCaption; SalesLineShpmtDtCaptionLbl)
            {
            }
            column(LineReceiptDateCaption; LineReceiptDateCaptionLbl)
            {
            }
            column(LineStatusCaption; LineStatusCaptionLbl)
            {
            }
            column(LineQuantityOnHandCaption; LineQuantityOnHandCaptionLbl)
            {
            }
            dataitem("Reservation Entry"; "Reservation Entry")
            {
                DataItemLink = "Source ID" = field("Document No."), "Source Ref. No." = field("Line No.");
                DataItemTableView = sorting("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date") where("Reservation Status" = const(Reservation), "Source Type" = const(37), "Source Batch Name" = const(''), "Source Prod. Order Line" = const(0));
                column(ReservText; ReservText)
                {
                }
                column(ShowReservDate; Format(ShowReservDate))
                {
                }
                column(Qty_ReservationEntry; Quantity)
                {
                }
                column(EntryQuantityOnHand; EntryQuantityOnHand)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(ShowResEntryBody; ShowReservationEntries)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Source Type" = DATABASE::"Item Ledger Entry" then
                        ShowReservDate := 0D
                    else
                        ShowReservDate := "Expected Receipt Date";
                    ReservText := ReservEngineMgt.CreateFromText("Reservation Entry");

                    if "Source Type" <> DATABASE::"Item Ledger Entry" then begin
                        if "Expected Receipt Date" > DocumentReceiptDate then
                            DocumentReceiptDate := "Expected Receipt Date";
                        EntryQuantityOnHand := 0;
                    end else
                        EntryQuantityOnHand := Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Source Subtype", "Sales Line"."Document Type");
                end;
            }

            trigger OnAfterGetRecord()
            var
                Location: Record Location;
                QtyToReserve: Decimal;
                QtyToReserveBase: Decimal;
            begin
                if Reserve <> Reserve::Never then begin
                    LineReceiptDate := 0D;
                    LineQuantityOnHand := 0;
                    if "Outstanding Qty. (Base)" = 0 then
                        LineStatus := LineStatus::Shipped
                    else begin
                        SalesLineReserve.ReservQuantity("Sales Line", QtyToReserve, QtyToReserveBase);
                        if QtyToReserveBase > 0 then begin
                            ReservEntry.InitSortingAndFilters(true);
                            SetReservationFilters(ReservEntry);
                            if ReservEntry.FindSet() then
                                repeat
                                    ReservEntryFrom.Reset();
                                    ReservEntryFrom.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                                    if ReservEntryFrom."Source Type" = DATABASE::"Item Ledger Entry" then
                                        LineQuantityOnHand := LineQuantityOnHand + ReservEntryFrom.Quantity;
                                until ReservEntry.Next() = 0;
                            CalcFields("Reserved Qty. (Base)");
                            if ("Outstanding Qty. (Base)" = LineQuantityOnHand) and ("Outstanding Qty. (Base)" <> 0) then
                                LineStatus := LineStatus::"Full Shipment"
                            else
                                if LineQuantityOnHand = 0 then
                                    LineStatus := LineStatus::"No Shipment"
                                else
                                    LineStatus := LineStatus::"Partial Shipment"
                        end else
                            LineStatus := LineStatus::"Full Shipment";
                    end;
                end else begin
                    LineReceiptDate := 0D;
                    SalesLineReserve.ReservQuantity("Sales Line", QtyToReserve, QtyToReserveBase);
                    LineQuantityOnHand := QtyToReserveBase;
                    if "Outstanding Qty. (Base)" = 0 then
                        LineStatus := LineStatus::Shipped
                    else
                        LineStatus := LineStatus::"Full Shipment";
                end;

                if ModifyQtyToShip and ("Document Type" = "Document Type"::Order) and
                   ("Qty. to Ship (Base)" <> LineQuantityOnHand)
                then begin
                    if "Location Code" <> '' then
                        Location.Get("Location Code");

                    if not Location."Directed Put-away and Pick" then begin
                        if "Qty. per Unit of Measure" = 0 then
                            "Qty. per Unit of Measure" := 1;
                        Validate("Qty. to Ship",
                          Round(LineQuantityOnHand / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
                        Modify();
                        OnAfterSalesLineModify("Sales Line");
                    end;
                end;

                if ClearDocumentStatus then begin
                    DocumentReceiptDate := 0D;
                    DocumentStatus := DocumentStatus::" ";
                    ClearDocumentStatus := false;
                    SalesHeader.Get("Document Type", "Document No.");
                end;

                if LineReceiptDate > DocumentReceiptDate then
                    DocumentReceiptDate := LineReceiptDate;

                case DocumentStatus of
                    DocumentStatus::" ":
                        DocumentStatus := LineStatus;
                    DocumentStatus::Shipped:
                        case LineStatus of
                            LineStatus::Shipped:
                                DocumentStatus := DocumentStatus::Shipped;
                            LineStatus::"Full Shipment",
                          LineStatus::"Partial Shipment":
                                DocumentStatus := DocumentStatus::"Partial Shipment";
                            LineStatus::"No Shipment":
                                DocumentStatus := DocumentStatus::"No Shipment";
                        end;
                    DocumentStatus::"Full Shipment":
                        case LineStatus of
                            LineStatus::Shipped,
                          LineStatus::"Full Shipment":
                                DocumentStatus := DocumentStatus::"Full Shipment";
                            LineStatus::"Partial Shipment",
                          LineStatus::"No Shipment":
                                DocumentStatus := DocumentStatus::"Partial Shipment";
                        end;
                    DocumentStatus::"Partial Shipment":
                        DocumentStatus := DocumentStatus::"Partial Shipment";
                    DocumentStatus::"No Shipment":
                        case LineStatus of
                            LineStatus::Shipped,
                          LineStatus::"No Shipment":
                                DocumentStatus := DocumentStatus::"No Shipment";
                            LineStatus::"Full Shipment",
                          LineStatus::"Partial Shipment":
                                DocumentStatus := DocumentStatus::"Partial Shipment";
                        end;
                end;

                ShowSalesLineGrHeader2 := false;
                if ((OldDocumentType <> "Document Type") or
                    (OldDocumentNo <> "Document No."))
                then
                    if ShowSalesLines then
                        ShowSalesLineGrHeader2 := true;

                OldDocumentNo := "Document No.";
                OldDocumentType := "Document Type";

                TempSalesLines := "Sales Line";
                ClearDocumentStatus := true;

                if TempSalesLines.Next() <> 0 then
                    ClearDocumentStatus := (TempSalesLines."Document No." <> OldDocumentNo) or (TempSalesLines."Document Type" <> OldDocumentType);
            end;

            trigger OnPreDataItem()
            begin
                ClearDocumentStatus := true;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Sales Reservation Avail.';
        AboutText = 'Get an overview of the items that are available to fulfill sales orders and ensure that inventory reservations are accurate.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowSalesLines; ShowSalesLines)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Show Sales Lines';
                        ToolTip = 'Specifies if you want the report to include a line for each sales line. If you do not place a check mark in the check box, the report will include one line for each document.';

                        trigger OnValidate()
                        begin
                            if not ShowSalesLines then
                                ShowReservationEntries := false;
                        end;
                    }
                    field(ShowReservationEntries; ShowReservationEntries)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Show Reservation Entries';
                        ToolTip = 'Specifies if you want the report to include reservation entries. The reservation entry will be printed below the line for which the items have been reserved. You can only use this option if you have also placed a check mark in the Show Sales Lines check box.';

                        trigger OnValidate()
                        begin
                            if ShowReservationEntries and not ShowSalesLines then
                                Error(Text000);
                        end;
                    }
                    field(ModifyQuantityToShip; ModifyQtyToShip)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Modify Qty. to Ship in Order Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the program to enter the quantity that is available for shipment in the Qty. to Ship field on the sales lines.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        SalesHeader: Record "Sales Header";
        ReservEntry: Record "Reservation Entry";
        ReservEntryFrom: Record "Reservation Entry";
        TempSalesLines: Record "Sales Line";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        OldDocumentNo: Code[20];
        OldDocumentType: Enum "Sales Line Type";
        ShowSalesLineGrHeader2: Boolean;
        ShowSalesLines: Boolean;
        ShowReservationEntries: Boolean;
        ModifyQtyToShip: Boolean;
        ClearDocumentStatus: Boolean;
        ReservText: Text[80];
        ShowReservDate: Date;
        LineReceiptDate: Date;
        DocumentReceiptDate: Date;
        LineStatus: Option " ",Shipped,"Full Shipment","Partial Shipment","No Shipment";
        DocumentStatus: Option " ",Shipped,"Full Shipment","Partial Shipment","No Shipment";
        LineQuantityOnHand: Decimal;
        EntryQuantityOnHand: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Sales lines must be shown.';
#pragma warning restore AA0074
        SalesResrvtnAvalbtyCaptionLbl: Label 'Sales Reservation Availability';
        CurrRepPageNoCaptionLbl: Label 'Page';
        SalesLineShpmtDtCaptionLbl: Label 'Shipment Date';
        LineReceiptDateCaptionLbl: Label 'Expected Receipt Date';
        LineStatusCaptionLbl: Label 'Shipment Status';
        LineQuantityOnHandCaptionLbl: Label 'Quantity on Hand (Base)';

    procedure InitializeRequest(NewShowSalesLines: Boolean; NewShowReservationEntries: Boolean; NewModifyQtyToShip: Boolean)
    begin
        ShowSalesLines := NewShowSalesLines;
        ShowReservationEntries := NewShowReservationEntries;
        ModifyQtyToShip := NewModifyQtyToShip;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineModify(var SalesLine: Record "Sales Line")
    begin
    end;
}

