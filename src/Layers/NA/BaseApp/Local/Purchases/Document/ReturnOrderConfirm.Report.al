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
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Globalization;
using System.Utilities;

report 10126 "Return Order Confirm"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Document/ReturnOrderConfirm.rdlc';
    Caption = 'Return Order Confirm';

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Return Order"));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Buy-from Vendor No.", "Pay-to Vendor No.", "No. Printed";
            RequestFilterHeading = 'Return Order';
            column(No_PurchHeader; "No.")
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
                    column(ExpRectDate_PurchHeader; "Purchase Header"."Expected Receipt Date")
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
                    column(BuyfromVendNo_PurchHeader; "Purchase Header"."Buy-from Vendor No.")
                    {
                    }
                    column(YourRef_PurchHeader; "Purchase Header"."Your Reference")
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(OrderDate_PurchHeader; "Purchase Header"."Order Date")
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
                    column(ShipmentMethodDesc; ShipmentMethod.Description)
                    {
                    }
                    column(PaymentTermsDesc; PaymentTerms.Description)
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInformation."Phone No.")
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(ToCaption; ToCaptionLbl)
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
                    column(ReturnOrderConfirmationCaption; ReturnOrderConfirmationCaptionLbl)
                    {
                    }
                    column(ReturnOrderNumberCaption; ReturnOrderNumberCaptionLbl)
                    {
                    }
                    column(ReturnOrderDateCaption; ReturnOrderDateCaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    column(ShipViaCaption; ShipViaCaptionLbl)
                    {
                    }
                    column(TermsCaption; TermsCaptionLbl)
                    {
                    }
                    column(PhoneNoCaption; PhoneNoCaptionLbl)
                    {
                    }
                    column(FOBCaption; FOBCaptionLbl)
                    {
                    }
                    dataitem("Purchase Line"; "Purchase Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Purchase Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const("Return Order"));
                        column(ItemNoTo_PrintPurchLine; ItemNumberToPrint)
                        {
                        }
                        column(umo_PrintPurchLine; "Unit of Measure")
                        {
                        }
                        column(Qty_PrintPurchLine; Quantity)
                        {
                        }
                        column(Desc_PrintPurchLine; Description)
                        {
                        }
                        column(PrintFooter_PrintPurchLine; PrintFooter)
                        {
                        }
                        column(DocNo_PrintPurchLine; "Document No.")
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
                        column(QuantityCaption; QuantityCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            if "Vendor Item No." <> '' then
                                ItemNumberToPrint := "Vendor Item No."
                            else
                                ItemNumberToPrint := "No.";

                            if Type = Type::" " then begin
                                ItemNumberToPrint := '';
                                "Unit of Measure" := '';
                                "Line Amount" := 0;
                                "Inv. Discount Amount" := 0;
                                Quantity := 0;
                            end;

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
                            PurchasePrinted.Run("Purchase Header");
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

                if "Payment Terms Code" = '' then
                    Clear(PaymentTerms)
                else
                    PaymentTerms.Get("Payment Terms Code");

                if "Shipment Method Code" = '' then
                    Clear(ShipmentMethod)
                else
                    ShipmentMethod.Get("Shipment Method Code");

                FormatAddress.PurchHeaderBuyFrom(BuyFromAddress, "Purchase Header");
                FormatAddress.PurchHeaderShipTo(ShipToAddress, "Purchase Header");

                if not CurrReport.Preview then begin
                    if ArchiveDocument then
                        ArchiveManagement.StorePurchDocument("Purchase Header", LogInteraction);

                    if LogInteraction then begin
                        CalcFields("No. of Archived Versions");
                        SegManagement.LogDocument(
                          22, "No.", "Doc. No. Occurrence", "No. of Archived Versions", DATABASE::Vendor, "Buy-from Vendor No.",
                          "Purchaser Code", "Campaign No.", "Posting Description", '');
                    end;
                end;
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
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies of each blanket purchase order, in addition to the original, that you want to print.';
                    }
                    field(PrintCompanyAddress; PrintCompany)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if you are printing on plain paper or if your company address is not pre-printed on your forms. If you do not select this field, the report will omit your company''s address.';
                    }
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Archive Document';
                        Enabled = ArchiveDocumentEnable;
                        ToolTip = 'Specifies if the document is archived when you run the report.';

                        trigger OnValidate()
                        begin
                            if not ArchiveDocument then
                                LogInteraction := false;
                        end;
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if the interaction with the vendor is logged when ,you run the report.';

                        trigger OnValidate()
                        begin
                            if LogInteraction then
                                ArchiveDocument := ArchiveDocumentEnable;
                        end;
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
            ArchiveDocumentEnable := true;
        end;

        trigger OnOpenPage()
        begin
            ArchiveDocument := ArchiveManagement.PurchaseDocArchiveGranule();
            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Purch. Ord.") <> '';

            ArchiveDocumentEnable := ArchiveDocument;
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
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
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
        PurchasePrinted: Codeunit "Purch.Header-Printed";
        FormatAddress: Codeunit "Format Address";
        ArchiveManagement: Codeunit ArchiveManagement;
        SegManagement: Codeunit SegManagement;
        ArchiveDocument: Boolean;
        LogInteraction: Boolean;
        Text000: Label 'COPY';
        ArchiveDocumentEnable: Boolean;
        LogInteractionEnable: Boolean;
        ToCaptionLbl: Label 'To:';
        ReceiveByCaptionLbl: Label 'Receive By';
        VendorIDCaptionLbl: Label 'Vendor ID';
        ConfirmToCaptionLbl: Label 'Confirm To';
        BuyerCaptionLbl: Label 'Buyer';
        ShipCaptionLbl: Label 'Ship';
        ReturnOrderConfirmationCaptionLbl: Label 'Return Order Confirmation';
        ReturnOrderNumberCaptionLbl: Label 'Return Order Number:';
        ReturnOrderDateCaptionLbl: Label 'Return Order Date:';
        PageCaptionLbl: Label 'Page:';
        ShipViaCaptionLbl: Label 'Ship Via';
        TermsCaptionLbl: Label 'Terms';
        PhoneNoCaptionLbl: Label 'Phone No.';
        FOBCaptionLbl: Label 'FOB';
        ItemNoCaptionLbl: Label 'Item No.';
        UnitCaptionLbl: Label 'Unit';
        DescriptionCaptionLbl: Label 'Description';
        QuantityCaptionLbl: Label 'Quantity';
}

