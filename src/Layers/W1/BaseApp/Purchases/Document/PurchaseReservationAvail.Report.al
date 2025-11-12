// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;

report 409 "Purchase Reservation Avail."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Document/PurchaseReservationAvail.rdlc';
    ApplicationArea = Reservation;
    Caption = 'Purchase Reservation Avail.';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Purchase Line"; "Purchase Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where(Type = const(Item));
            RequestFilterFields = "Document Type", "Document No.", "Line No.", "No.", "Location Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ShowPurchLines; ShowPurchLines)
            {
            }
            column(ShowReservationEntries2; ShowReservationEntries2)
            {
            }
            column(DocTypeDocNo_PurchLine; StrSubstNo('%1 %2', "Document Type", "Document No."))
            {
            }
            column(No_PurchaseLine; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_PurchLine; Description)
            {
                IncludeCaption = true;
            }
            column(ExpctRecptDate_PurchLine; Format("Expected Receipt Date"))
            {
                IncludeCaption = false;
            }
            column(OutstQtyBase_PurchLine; "Outstanding Qty. (Base)")
            {
                IncludeCaption = true;
            }
            column(ReservQtyBase_PurchLine; "Reserved Qty. (Base)")
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
            column(DocumentReceiptDate; Format(DocumentReceiptDate))
            {
            }
            column(DocumentStatus; DocumentStatus)
            {
                OptionCaption = ' ,Shipped,Full Shipment,Partial Shipment,No Shipment';
            }
            column(PurchHeaderExpctdRecptDt; Format(PurchHeader."Expected Receipt Date"))
            {
            }
            column(DocType_PurchLine; "Document Type")
            {
            }
            column(DocNo_PurchLine; "Document No.")
            {
            }
            column(LineNo_PurchLine; "Line No.")
            {
            }
            column(PurchReservAvailCap; PurchReservAvailCapLbl)
            {
            }
            column(CurrReportPAGENOCap; CurrReportPAGENOCapLbl)
            {
            }
            column(PurchLineExpctdRecptDtCap; PurchLineExpctdRecptDtCapLbl)
            {
            }
            column(LineStatusCap; LineStatusCapLbl)
            {
            }
            column(LineQtyOnHandCap; LineQtyOnHandCapLbl)
            {
            }
            dataitem("Reservation Entry"; "Reservation Entry")
            {
                DataItemLink = "Source ID" = field("Document No."), "Source Ref. No." = field("Line No.");
                DataItemTableView = sorting("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date") where("Reservation Status" = const(Reservation), "Source Type" = const(39), "Source Batch Name" = const(''), "Source Prod. Order Line" = const(0));
                column(ReservText; ReservText)
                {
                }
                column(ShowReservDate; Format(ShowReservDate))
                {
                }
                column(Quantity_ReservEntry; Quantity)
                {
                }
                column(EntryQuantityOnHand; EntryQuantityOnHand)
                {
                    DecimalPlaces = 0 : 5;
                }

                trigger OnAfterGetRecord()
                begin
                    if "Source Type" = Database::"Item Ledger Entry" then
                        ShowReservDate := 0D
                    else
                        ShowReservDate := "Expected Receipt Date";
                    ReservText := ReservEngineMgt.CreateFromText("Reservation Entry");

                    if "Source Type" <> Database::"Item Ledger Entry" then begin
                        if "Expected Receipt Date" > LineReceiptDate then
                            LineReceiptDate := "Expected Receipt Date";
                        if "Expected Receipt Date" > DocumentReceiptDate then
                            DocumentReceiptDate := "Expected Receipt Date";
                        EntryQuantityOnHand := 0;
                    end else
                        EntryQuantityOnHand := Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Source Subtype", "Purchase Line"."Document Type");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if ("Document No." <> DocumentNoOld) or ("Document Type".AsInteger() <> DocumentTypeOld) then
                    ClearDocumentStatus := true
                else
                    ClearDocumentStatus := false;
                DocumentNoOld := "Document No.";
                DocumentTypeOld := "Document Type".AsInteger();
                LineReceiptDate := 0D;
                LineQuantityOnHand := 0;
                if "Outstanding Qty. (Base)" = 0 then
                    LineStatus := LineStatus::Shipped
                else
                    if PurchLineReserve.ReservQuantity("Purchase Line") > 0 then begin
                        ReservEntry.Reset();
                        ReservEntry.InitSortingAndFilters(true);
                        SetReservationFilters(ReservEntry);
                        ReservEntry.SetFilter("Source Type", '<>%1', Database::"Item Ledger Entry");
                        if ReservEntry.Find('+') then begin
                            LineReceiptDate := ReservEntry."Expected Receipt Date";
                            ReservEntry.SetRange("Source Type", Database::"Item Ledger Entry");
                            if ReservEntry.Find('-') then begin
                                repeat
                                    LineQuantityOnHand := LineQuantityOnHand + ReservEntry.Quantity;
                                until ReservEntry.Next() = 0;
                                LineStatus := LineStatus::"Partial Shipment";
                            end else
                                LineStatus := LineStatus::"No Shipment";
                        end else begin
                            CalcFields("Reserved Qty. (Base)");
                            LineQuantityOnHand := "Reserved Qty. (Base)";
                            if Abs("Outstanding Qty. (Base)") = Abs("Reserved Qty. (Base)") then
                                LineStatus := LineStatus::"Full Shipment"
                            else
                                if "Reserved Qty. (Base)" = 0 then
                                    LineStatus := LineStatus::"No Shipment"
                                else
                                    LineStatus := LineStatus::"Partial Shipment";
                        end;
                    end else
                        LineStatus := LineStatus::"Full Shipment";

                if ModifyQtyToShip and ("Document Type" = "Document Type"::Order) and
                   ("Qty. to Receive (Base)" <> LineQuantityOnHand)
                then begin
                    if "Qty. per Unit of Measure" = 0 then
                        "Qty. per Unit of Measure" := 1;
                    Validate("Qty. to Receive",
                      Round(LineQuantityOnHand / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
                    Modify();
                    OnAfterPurchLineModify("Purchase Line");
                end;

                if ClearDocumentStatus then begin
                    DocumentReceiptDate := 0D;
                    DocumentStatus := DocumentStatus::" ";
                    ClearDocumentStatus := false;
                    PurchHeader.Get("Document Type", "Document No.");
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
            end;

            trigger OnPreDataItem()
            begin
                ClearDocumentStatus := true;

                DocumentTypeOld := 1000;
                DocumentNoOld := '';
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Purchase Reservation Avail.';
        AboutText = 'Explore the availability of items for shipment on purchase documents, such as return orders.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowPurchLine; ShowPurchLines)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Show Purchase Lines';
                        ToolTip = 'Specifies if you want the report to include a line for each purchase line. If you do not place a check mark in the check box, the report will include one line for each document.';

                        trigger OnValidate()
                        begin
                            if not ShowPurchLines then
                                ShowReservationEntries := false;
                        end;
                    }
                    field(ShowReservationEntries; ShowReservationEntries)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Show Reservation Entries';
                        ToolTip = 'Specifies if you want the report to include reservation entries. The reservation entry will be printed below the line for which the items have been reserved. You can only check this option if you have also placed a check mark in the Show Purchase Lines check box.';

                        trigger OnValidate()
                        begin
                            if ShowReservationEntries and not ShowPurchLines then
                                Error(Text000);
                        end;
                    }
                    field(ModifyQtuantityToShip; ModifyQtyToShip)
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Modify Qty. to Receive in Order Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the program to enter the quantity that is available for shipment in the Qty. to Receive field on the purchase lines. (The Qty. to Receive field contains the quantity to ship on purchase credit memos or negative purchase order lines.)';
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

    trigger OnPreReport()
    begin
        ShowReservationEntries2 := ShowReservationEntries;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Purchase lines must be shown.';
#pragma warning restore AA0074
        PurchHeader: Record "Purchase Header";
        ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        ShowPurchLines: Boolean;
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
        ShowReservationEntries2: Boolean;
        DocumentNoOld: Code[20];
        DocumentTypeOld: Option;
        PurchReservAvailCapLbl: Label 'Purchase Reservation Availability';
        CurrReportPAGENOCapLbl: Label 'Page';
        PurchLineExpctdRecptDtCapLbl: Label 'Expected Receipt Date';
        LineStatusCapLbl: Label 'Shipment Status';
        LineQtyOnHandCapLbl: Label 'Quantity on Hand (Base)';

    procedure InitializeRequest(NewShowPurchLines: Boolean; NewShowReservationEntries: Boolean; NewModifyQtyToShip: Boolean)
    begin
        ShowPurchLines := NewShowPurchLines;
        ShowReservationEntries := NewShowReservationEntries;
        ModifyQtyToShip := NewModifyQtyToShip;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineModify(var PurchLine: Record "Purchase Line")
    begin
    end;
}

