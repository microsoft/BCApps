// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Globalization;
using System.Utilities;

report 10124 "Purchase Receipt NA"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Document/PurchaseReceiptNA.rdlc';
    Caption = 'Purchase Receipt';

    dataset
    {
        dataitem("Purch. Rcpt. Header"; "Purch. Rcpt. Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.", "No. Printed";
            RequestFilterHeading = 'Purchase Receipt';
            column(No_PurchRcptHeader; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyAddr1; CompanyAddress[1])
                    {
                    }
                    column(CompanyAddr2; CompanyAddress[2])
                    {
                    }
                    column(CompanyAddr3; CompanyAddress[3])
                    {
                    }
                    column(CompanyAddr4; CompanyAddress[4])
                    {
                    }
                    column(CompanyAddr5; CompanyAddress[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddress[6])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(BuyFromAddr1; BuyFromAddress[1])
                    {
                    }
                    column(BuyFromAddr2; BuyFromAddress[2])
                    {
                    }
                    column(BuyFromAddr3; BuyFromAddress[3])
                    {
                    }
                    column(BuyFromAddr4; BuyFromAddress[4])
                    {
                    }
                    column(BuyFromAddr5; BuyFromAddress[5])
                    {
                    }
                    column(BuyFromAddr6; BuyFromAddress[6])
                    {
                    }
                    column(BuyFromAddr7; BuyFromAddress[7])
                    {
                    }
                    column(ExpRcptDate_PurchRcptHeader; "Purch. Rcpt. Header"."Expected Receipt Date")
                    {
                    }
                    column(ShipToAddr1; ShipToAddress[1])
                    {
                    }
                    column(ShipToAddr2; ShipToAddress[2])
                    {
                    }
                    column(ShipToAddr3; ShipToAddress[3])
                    {
                    }
                    column(ShipToAddr4; ShipToAddress[4])
                    {
                    }
                    column(ShipToAddr5; ShipToAddress[5])
                    {
                    }
                    column(ShipToAddr6; ShipToAddress[6])
                    {
                    }
                    column(ShipToAddr7; ShipToAddress[7])
                    {
                    }
                    column(BuyfrmVendNo_PurchRcptHeader; "Purch. Rcpt. Header"."Buy-from Vendor No.")
                    {
                    }
                    column(YourRef_PurchRcptHeader; "Purch. Rcpt. Header"."Your Reference")
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(No1_PurchRcptHeader; "Purch. Rcpt. Header"."No.")
                    {
                    }
                    column(DocDate_PurchRcptHeader; "Purch. Rcpt. Header"."Document Date")
                    {
                    }
                    column(CompanyAddr7; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddr8; CompanyAddress[8])
                    {
                    }
                    column(BuyFromAddr8; BuyFromAddress[8])
                    {
                    }
                    column(ShipToAddr8; ShipToAddress[8])
                    {
                    }
                    column(ShipmentMethodDesc; ShipmentMethod.Description)
                    {
                    }
                    column(OrderNo_PurchRcptHeader; "Purch. Rcpt. Header"."Order No.")
                    {
                    }
                    column(OrderDate_PurchRcptHeader; "Purch. Rcpt. Header"."Order Date")
                    {
                    }
                    column(myCopyNo; CopyNo)
                    {
                    }
                    column(FromCaption; FromCaptionLbl)
                    {
                    }
                    column(ReceiveByCaption; ReceiveByCaptionLbl)
                    {
                    }
                    column(VendorIDCaption; VendorIDCaptionLbl)
                    {
                    }
                    column(ConfirmToCaption; ConfirmToCaptionLbl)
                    {
                    }
                    column(BuyerCaption; BuyerCaptionLbl)
                    {
                    }
                    column(ShipCaption; ShipCaptionLbl)
                    {
                    }
                    column(ToCaption; ToCaptionLbl)
                    {
                    }
                    column(PurchaseReceiptCaption; PurchaseReceiptCaptionLbl)
                    {
                    }
                    column(PurchaseReceiptNumberCaption; PurchaseReceiptNumberCaptionLbl)
                    {
                    }
                    column(PurchaseReceiptDateCaption; PurchaseReceiptDateCaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    column(ShipViaCaption; ShipViaCaptionLbl)
                    {
                    }
                    column(PONumberCaption; PONumberCaptionLbl)
                    {
                    }
                    column(PurchaseCaption; PurchaseCaptionLbl)
                    {
                    }
                    column(PODateCaption; PODateCaptionLbl)
                    {
                    }
                    dataitem("Purch. Rcpt. Line"; "Purch. Rcpt. Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Purch. Rcpt. Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(ItemNumberToPrint_PurchRcptLine; ItemNumberToPrint)
                        {
                        }
                        column(UnitofMeasure_PurchRcptLine; "Unit of Measure")
                        {
                        }
                        column(Qty_PurchRcptLine; Quantity)
                        {
                        }
                        column(OrderedQty_PurchRcptLine; OrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(BackOrderedQty_PurchRcptLine; BackOrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Desc_PurchRcptLine; Description)
                        {
                        }
                        column(PrintFooter_PurchRcptLine; PrintFooter)
                        {
                        }
                        column(LineNo_PurchRcptLine; "Line No.")
                        {
                        }
                        column(ItemNoCaption; ItemNoCaptionLbl)
                        {
                        }
                        column(UnitCaption; UnitCaptionLbl)
                        {
                        }
                        column(DescriptionCaption; DescriptionCaptionLbl)
                        {
                        }
                        column(ReceivedCaption; ReceivedCaptionLbl)
                        {
                        }
                        column(OrderedCaption; OrderedCaptionLbl)
                        {
                        }
                        column(BackOrderedCaption; BackOrderedCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            OrderedQuantity := 0;
                            BackOrderedQuantity := 0;
                            if "Order No." = '' then
                                OrderedQuantity := Quantity
                            else
                                if OrderLine.Get(1, "Order No.", "Order Line No.") then begin
                                    OrderedQuantity := OrderLine.Quantity;
                                    BackOrderedQuantity := OrderLine."Outstanding Quantity";
                                end else begin
                                    ReceiptLine.SetCurrentKey("Order No.", "Order Line No.");
                                    ReceiptLine.SetRange("Order No.", "Order No.");
                                    ReceiptLine.SetRange("Order Line No.", "Order Line No.");
                                    ReceiptLine.Find('-');
                                    repeat
                                        OrderedQuantity := OrderedQuantity + ReceiptLine.Quantity;
                                    until 0 = ReceiptLine.Next();
                                end;

                            if Type = Type::" " then begin
                                ItemNumberToPrint := '';
                                "Unit of Measure" := '';
                                OrderedQuantity := 0;
                                BackOrderedQuantity := 0;
                                Quantity := 0;
                            end else
                                if Type = Type::"G/L Account" then
                                    ItemNumberToPrint := "Vendor Item No."
                                else
                                    ItemNumberToPrint := "No.";

                            if OnLineNumber = NumberOfLines then
                                PrintFooter := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            NumberOfLines := Count;
                            OnLineNumber := 0;
                            PrintFooter := false;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            PurchaseRcptPrinted.Run("Purch. Rcpt. Header");
                        CurrReport.Break();
                    end;
                    CopyNo := CopyNo + 1;
                    if CopyNo = 1 then // Original
                        Clear(CopyTxt)
                    else
                        CopyTxt := Text000;
                end;

                trigger OnPreDataItem()
                begin
                    NoLoops := 1 + Abs(NoCopies);
                    if NoLoops <= 0 then
                        NoLoops := 1;
                    CopyNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrintCompany then
                    if RespCenter.Get("Responsibility Center") then begin
                        FormatAddress.RespCenter(CompanyAddress, RespCenter);
                        CompanyInformation."Phone No." := RespCenter."Phone No.";
                        CompanyInformation."Fax No." := RespCenter."Fax No.";
                    end;
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                if "Purchaser Code" = '' then
                    Clear(SalesPurchPerson)
                else
                    SalesPurchPerson.Get("Purchaser Code");

                if "Shipment Method Code" = '' then
                    Clear(ShipmentMethod)
                else
                    ShipmentMethod.Get("Shipment Method Code");

                if "Buy-from Vendor No." = '' then begin
                    "Buy-from Vendor Name" := Text009;
                    "Ship-to Name" := Text009;
                end;

                FormatAddress.PurchRcptBuyFrom(BuyFromAddress, "Purch. Rcpt. Header");
                FormatAddress.PurchRcptShipTo(ShipToAddress, "Purch. Rcpt. Header");

                if LogInteraction then
                    if not CurrReport.Preview then
                        SegManagement.LogDocument(
                          15, "No.", 0, 0, DATABASE::Vendor, "Buy-from Vendor No.", "Purchaser Code", '', "Posting Description", '');
            end;

            trigger OnPreDataItem()
            begin
                if PrintCompany then
                    FormatAddress.Company(CompanyAddress, CompanyInformation)
                else
                    Clear(CompanyAddress);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NumberOfCopies; NoCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies of each document (in addition to the original) that you want to print.';
                    }
                    field(PrintCompanyAddress; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if your company address is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s address.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the related interactions with the involved contact person in the Interaction Log Entry table.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Purch. Rcpt.") <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get('');
    end;

    var
        ShipmentMethod: Record "Shipment Method";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
        ReceiptLine: Record "Purch. Rcpt. Line";
        OrderLine: Record "Purchase Line";
        RespCenter: Record "Responsibility Center";
        LanguageMgt: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BuyFromAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        ItemNumberToPrint: Text[50];
        PrintCompany: Boolean;
        PrintFooter: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        PurchaseRcptPrinted: Codeunit "Purch.Rcpt.-Printed";
        FormatAddress: Codeunit "Format Address";
        OrderedQuantity: Decimal;
        BackOrderedQuantity: Decimal;
        SegManagement: Codeunit SegManagement;
        LogInteraction: Boolean;
        Text000: Label 'COPY';
        Text009: Label 'VOID RECEIPT';
        LogInteractionEnable: Boolean;
        FromCaptionLbl: Label 'From:';
        ReceiveByCaptionLbl: Label 'Receive By';
        VendorIDCaptionLbl: Label 'Vendor ID';
        ConfirmToCaptionLbl: Label 'Confirm To';
        BuyerCaptionLbl: Label 'Buyer';
        ShipCaptionLbl: Label 'Ship';
        ToCaptionLbl: Label 'To:';
        PurchaseReceiptCaptionLbl: Label 'Purchase Receipt';
        PurchaseReceiptNumberCaptionLbl: Label 'Purchase Receipt Number:';
        PurchaseReceiptDateCaptionLbl: Label 'Purchase Receipt Date:';
        PageCaptionLbl: Label 'Page:';
        ShipViaCaptionLbl: Label 'Ship Via';
        PONumberCaptionLbl: Label 'P.O. Number';
        PurchaseCaptionLbl: Label 'Purchase';
        PODateCaptionLbl: Label 'P.O. Date';
        ItemNoCaptionLbl: Label 'Item No.';
        UnitCaptionLbl: Label 'Unit';
        DescriptionCaptionLbl: Label 'Description';
        ReceivedCaptionLbl: Label 'Received';
        OrderedCaptionLbl: Label 'Ordered';
        BackOrderedCaptionLbl: Label 'Back Ordered';
}

