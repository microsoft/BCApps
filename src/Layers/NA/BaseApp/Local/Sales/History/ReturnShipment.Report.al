// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Globalization;
using System.Utilities;

report 10127 "Return Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/History/ReturnShipment.rdlc';
    Caption = 'Return Shipment';

    dataset
    {
        dataitem("Return Shipment Header"; "Return Shipment Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.", "No. Printed";
            RequestFilterHeading = 'Return Shipment';
            column(No_ReturnShipmentHeader; "No.")
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
            column(ReturnShipmentCaption; ReturnShipmentCaptionLbl)
            {
            }
            column(ReturnShpNumberCaption; ReturnShpNumberCaptionLbl)
            {
            }
            column(ReturnShipmentDateCaption; ReturnShipmentDateCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ShipViaCaption; ShipViaCaptionLbl)
            {
            }
            column(RONumberCaption; RONumberCaptionLbl)
            {
            }
            column(PurchaseCaption; PurchaseCaptionLbl)
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
            column(ShippedCaption; ShippedCaptionLbl)
            {
            }
            column(AuthorizedCaption; AuthorizedCaptionLbl)
            {
            }
            column(ToBeShippedCaption; ToBeShippedCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyAddress1; CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress2; CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress3; CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress4; CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress5; CompanyAddress[5])
                    {
                    }
                    column(CompanyAddress6; CompanyAddress[6])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(BuyFromAddress1; BuyFromAddress[1])
                    {
                    }
                    column(BuyFromAddress2; BuyFromAddress[2])
                    {
                    }
                    column(BuyFromAddress3; BuyFromAddress[3])
                    {
                    }
                    column(BuyFromAddress4; BuyFromAddress[4])
                    {
                    }
                    column(BuyFromAddress5; BuyFromAddress[5])
                    {
                    }
                    column(BuyFromAddress6; BuyFromAddress[6])
                    {
                    }
                    column(BuyFromAddress7; BuyFromAddress[7])
                    {
                    }
                    column(ExpectedRcptDate_ReturnShpHdr; "Return Shipment Header"."Expected Receipt Date")
                    {
                    }
                    column(ShipToAddress1; ShipToAddress[1])
                    {
                    }
                    column(ShipToAddress2; ShipToAddress[2])
                    {
                    }
                    column(ShipToAddress3; ShipToAddress[3])
                    {
                    }
                    column(ShipToAddress4; ShipToAddress[4])
                    {
                    }
                    column(ShipToAddress5; ShipToAddress[5])
                    {
                    }
                    column(ShipToAddress6; ShipToAddress[6])
                    {
                    }
                    column(ShipToAddress7; ShipToAddress[7])
                    {
                    }
                    column(BuyfromVendNo_ReturnShpHdr; "Return Shipment Header"."Buy-from Vendor No.")
                    {
                    }
                    column(YourReference_ReturnShpHdr; "Return Shipment Header"."Your Reference")
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(DocDate_ReturnShpHdr; "Return Shipment Header"."Document Date")
                    {
                    }
                    column(CompanyAddress7; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddress8; CompanyAddress[8])
                    {
                    }
                    column(BuyFromAddress8; BuyFromAddress[8])
                    {
                    }
                    column(ShipToAddress8; ShipToAddress[8])
                    {
                    }
                    column(ShipmentMethodDescription; ShipmentMethod.Description)
                    {
                    }
                    column(ReturnOrderNo_ReturnShpHdr; "Return Shipment Header"."Return Order No.")
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    dataitem("Return Shipment Line"; "Return Shipment Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Return Shipment Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(ItemNumberToPrint; ItemNumberToPrint)
                        {
                        }
                        column(UOM_ReturnShipmentLine; "Unit of Measure")
                        {
                        }
                        column(Qty_ReturnShipmentLine; Quantity)
                        {
                        }
                        column(OrderedQuantity; OrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(BackOrderedQuantity; BackOrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(LineNo_ReturnShpLine; "Line No.")
                        {
                        }
                        column(Description_ReturnShpLine; Description)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            OrderedQuantity := 0;
                            BackOrderedQuantity := 0;
                            if "Return Order No." = '' then
                                OrderedQuantity := Quantity
                            else
                                if OrderLine.Get(5, "Return Order No.", "Return Order Line No.") then begin
                                    OrderedQuantity := OrderLine.Quantity;
                                    BackOrderedQuantity := OrderLine."Outstanding Quantity";
                                end else begin
                                    ReturnLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                                    ReturnLine.SetRange("Return Order No.", "Return Order No.");
                                    ReturnLine.SetRange("Return Order Line No.", "Return Order Line No.");
                                    ReturnLine.Find('-');
                                    repeat
                                        OrderedQuantity := OrderedQuantity + ReturnLine.Quantity;
                                    until 0 = ReturnLine.Next();
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
                        end;

                        trigger OnPreDataItem()
                        begin
                            OnLineNumber := 0;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            PurchaseShptPrinted.Run("Return Shipment Header");
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

                FormatAddress.PurchShptBuyFrom(BuyFromAddress, "Return Shipment Header");
                FormatAddress.PurchShptShipTo(ShipToAddress, "Return Shipment Header");

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
        ReturnLine: Record "Return Shipment Line";
        OrderLine: Record "Purchase Line";
        RespCenter: Record "Responsibility Center";
        LanguageMgt: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BuyFromAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        ItemNumberToPrint: Text[50];
        PrintCompany: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        OnLineNumber: Integer;
        PurchaseShptPrinted: Codeunit "Return Shipment - Printed";
        FormatAddress: Codeunit "Format Address";
        OrderedQuantity: Decimal;
        BackOrderedQuantity: Decimal;
        SegManagement: Codeunit SegManagement;
        LogInteraction: Boolean;
        Text000: Label 'COPY';
        Text009: Label 'VOID SHIPMENT';
        LogInteractionEnable: Boolean;
        FromCaptionLbl: Label 'From:';
        ReceiveByCaptionLbl: Label 'Receive By';
        VendorIDCaptionLbl: Label 'Vendor ID';
        ConfirmToCaptionLbl: Label 'Confirm To';
        BuyerCaptionLbl: Label 'Buyer';
        ShipCaptionLbl: Label 'Ship';
        ToCaptionLbl: Label 'To:';
        ReturnShipmentCaptionLbl: Label 'RETURN SHIPMENT';
        ReturnShpNumberCaptionLbl: Label 'Return Shipment Number:';
        ReturnShipmentDateCaptionLbl: Label 'Return Shipment Date:';
        PageCaptionLbl: Label 'Page:';
        ShipViaCaptionLbl: Label 'Ship Via';
        RONumberCaptionLbl: Label 'R.O. Number';
        PurchaseCaptionLbl: Label 'Purchase';
        ItemNoCaptionLbl: Label 'Item No.';
        UnitCaptionLbl: Label 'Unit';
        DescriptionCaptionLbl: Label 'Description';
        ShippedCaptionLbl: Label 'Shipped';
        AuthorizedCaptionLbl: Label 'Authorized';
        ToBeShippedCaptionLbl: Label 'To Be Shipped';
}

