// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Tracking;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 5913 "Service - Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/History/ServiceShipment.rdlc';
    Caption = 'Service - Shipment';
    WordMergeDataItem = "Service Shipment Header";

    dataset
    {
        dataitem("Service Shipment Header"; "Service Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Service Shipment';
            column(No_ServiceShptHrd; "No.")
            {
            }
            column(DocumentDate; DocumentDateLbl)
            {
            }
            column(EmailIdCaption; EmailIdCaptionLbl)
            {
            }
            column(HomePageCaption; HomePageCaptionLbl)
            {
            }
            column(SrvcShipHeaderCustNoCaption; SrvcShipHeaderCustNoCaptionLbl)
            {
            }
            column(WarrantyCaption; WarrantyCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(ServiceShptCopyText; StrSubstNo(Text002, CopyText))
                    {
                    }
                    column(ShipToAddr1; ShipToAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(ShipToAddr2; ShipToAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(ShipToAddr3; ShipToAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(ShipToAddr4; ShipToAddr[4])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(ShipToAddr5; ShipToAddr[5])
                    {
                    }
                    column(PhoneNo_CompanyInfo; CompanyInfo."Phone No.")
                    {
                    }
                    column(ShipToAddr6; ShipToAddr[6])
                    {
                    }
                    column(HomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(EMailId; CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyInfoVATRegnNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoBankName; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(CustNo_ServShptHrd; "Service Shipment Header"."Customer No.")
                    {
                    }
                    column(ServShptHrdDocDt; Format("Service Shipment Header"."Document Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(No1_ServiceShptHrd; "Service Shipment Header"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourRef_ServShptHrd; "Service Shipment Header"."Your Reference")
                    {
                    }
                    column(ShipToAddr7; ShipToAddr[7])
                    {
                    }
                    column(ShipToAddr8; ShipToAddr[8])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr7; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr8; CompanyAddr[8])
                    {
                    }
                    column(PostingDate_ServShptHrd; Format("Service Shipment Header"."Posting Date"))
                    {
                    }
                    column(PageCaption; StrSubstNo(Text003, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(ItemTrackingAppendixCaption; ItemTrackingAppendixCaptionLbl)
                    {
                    }
                    column(PhoneNoCaption; PhoneNoCaptionLbl)
                    {
                    }
                    column(VATRegNoCaption; VATRegNoCaptionLbl)
                    {
                    }
                    column(GiroNoCaption; GiroNoCaptionLbl)
                    {
                    }
                    column(BankNameCaption; BankNameCaptionLbl)
                    {
                    }
                    column(BankAccNoCaption; BankAccNoCaptionLbl)
                    {
                    }
                    column(ServiceShpHdrNoCaption; ServiceShpHdrNoCaptionLbl)
                    {
                    }
                    column(ServiceShpHdrPostingDateCaption; ServiceShpHdrPostingDateCaptionLbl)
                    {
                    }
                    column(CustNo_ServShptHrdCaption; "Service Shipment Header".FieldCaption("Customer No."))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Service Shipment Header";
                        DataItemTableView = sorting(Number);
                        column(DimText; DimText)
                        {
                        }
                        column(DimensionLoop1Number; Number)
                        {
                        }
                        column(HdrDimsCaption; HdrDimsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimText := DimTxtArr[Number];
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                            FindDimTxt("Service Shipment Header"."Dimension Set ID");
                            SetRange(Number, 1, DimTxtArrLength);
                        end;
                    }
                    dataitem("Service Shipment Item Line"; "Service Shipment Item Line")
                    {
                        DataItemLink = "No." = field("No.");
                        DataItemLinkReference = "Service Shipment Header";
                        DataItemTableView = sorting("No.", "Line No.");
                        column(ContractNo_ServShptItemLn; "Contract No.")
                        {
                        }
                        column(Des_ServShptItemLn; Description)
                        {
                        }
                        column(SerialNo_ServShptItemLn; "Serial No.")
                        {
                        }
                        column(ItemNo_ServShptItemLn; "Item No.")
                        {
                        }
                        column(ItemGrpCode_ServShptLn; "Service Item Group Code")
                        {
                        }
                        column(ServItemNo_ServShptItemLn; "Service Item No.")
                        {
                        }
                        column(Warranty; Format(Warranty))
                        {
                        }
                        column(LnNo_ServShptItemLn; "Line No.")
                        {
                        }
                        column(SrvcShpItemLineCaption; SrvcShpItemLineCaptionLbl)
                        {
                        }
                        column(ContractNo_ServShptItemLnCaption; FieldCaption("Contract No."))
                        {
                        }
                        column(Des_ServShptItemLnCaption; FieldCaption(Description))
                        {
                        }
                        column(SerialNo_ServShptItemLnCaption; FieldCaption("Serial No."))
                        {
                        }
                        column(ItemNo_ServShptItemLnCaption; FieldCaption("Item No."))
                        {
                        }
                        column(ItemGrpCode_ServShptLnCaption; FieldCaption("Service Item Group Code"))
                        {
                        }
                        column(ServItemNo_ServShptItemLnCaption; FieldCaption("Service Item No."))
                        {
                        }
                    }
                    dataitem("Service Shipment Line"; "Service Shipment Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Service Shipment Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(ServShptLnDescription; Description)
                        {
                        }
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(ShowCorrectionLines; ShowCorrectionLines)
                        {
                        }
                        column(ShowLotSN; ShowLotSN)
                        {
                        }
                        column(Type_ServiceShptItemLn; Type)
                        {
                        }
                        column(Qty_ServiceShptItemLn; Quantity)
                        {
                        }
                        column(UnitofMeasure_ServShptLn; "Unit of Measure")
                        {
                        }
                        column(No_ServiceShptItemLn; "No.")
                        {
                        }
                        column(QtyInvoiced_ServShptLine; "Quantity Invoiced")
                        {
                        }
                        column(QtyConsumed_ServShptLine; "Quantity Consumed")
                        {
                        }
                        column(LnNo_ServiceShptItemLn; "Line No.")
                        {
                        }
                        column(ServiceShpLineCaption; ServiceShpLineCaptionLbl)
                        {
                        }
                        column(QtyInvoicedCaption; QtyInvoicedCaptionLbl)
                        {
                        }
                        column(QtyConsumedCaption; QtyConsumedCaptionLbl)
                        {
                        }
                        column(ServShptLnDescriptionCaption; FieldCaption(Description))
                        {
                        }
                        column(Qty_ServiceShptItemLnCaption; FieldCaption(Quantity))
                        {
                        }
                        column(UnitofMeasure_ServShptLnCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(No_ServiceShptItemLnCaption; FieldCaption("No."))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimText_DimLoop2; DimText)
                            {
                            }
                            column(DimensionLoop2Number; Number)
                            {
                            }
                            column(LineDimsCaption; LineDimsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := DimTxtArr[Number];
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();
                                FindDimTxt("Service Shipment Line"."Dimension Set ID");
                                SetRange(Number, 1, DimTxtArrLength);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not ShowCorrectionLines and Correction then
                                CurrReport.Skip();
                        end;

                        trigger OnPostDataItem()
                        begin
                            if ShowLotSN then
                                TrackingSpecCount :=
                                  ItemTrackingDocMgt.RetrieveDocumentItemTracking(
                                      TempTrackingSpecification, "Service Shipment Header"."No.", DATABASE::"Service Shipment Header", 0);
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(BilltoCustNo_ServShptHrd; "Service Shipment Header"."Bill-to Customer No.")
                        {
                        }
                        column(CustAddr1; CustAddr[1])
                        {
                        }
                        column(CustAddr2; CustAddr[2])
                        {
                        }
                        column(CustAddr3; CustAddr[3])
                        {
                        }
                        column(CustAddr4; CustAddr[4])
                        {
                        }
                        column(CustAddr5; CustAddr[5])
                        {
                        }
                        column(CustAddr6; CustAddr[6])
                        {
                        }
                        column(CustAddr7; CustAddr[7])
                        {
                        }
                        column(CustAddr8; CustAddr[8])
                        {
                        }
                        column(BilltoAddrCaption; BilltoAddrCaptionLbl)
                        {
                        }
                        column(BilltoCustNo_ServShptHrdCaption; "Service Shipment Header".FieldCaption("Bill-to Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowCustAddr then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(ItemTrackingLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(TrackingSpecBufItemNo; TempTrackingSpecification."Item No.")
                        {
                        }
                        column(TrackingSpecBufDesc; TempTrackingSpecification.Description)
                        {
                        }
                        column(TrackingSpecBufLotNo; TempTrackingSpecification."Lot No.")
                        {
                        }
                        column(TrackingSpecBufSerialNo; TempTrackingSpecification."Serial No.")
                        {
                        }
                        column(TrackingSpecBufQty; TempTrackingSpecification."Quantity (Base)")
                        {
                        }
                        column(ShowTotal; ShowTotal)
                        {
                        }
                        column(ShowGroup; ShowGroup)
                        {
                        }
                        column(QuantityCaption; QuantityCaptionLbl)
                        {
                        }
                        column(SerialNoCaption; SerialNoCaptionLbl)
                        {
                        }
                        column(LotNoCaption; LotNoCaptionLbl)
                        {
                        }
                        column(DescriptionCaption; DescriptionCaptionLbl)
                        {
                        }
                        dataitem(TotalItemTracking; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = const(1));
                            column(TotalQty; TotalQty)
                            {
                            }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TempTrackingSpecification.FindSet()
                            else
                                TempTrackingSpecification.Next();

                            if not ShowCorrectionLines and TempTrackingSpecification.Correction then
                                CurrReport.Skip();
                            if TempTrackingSpecification.Correction then
                                TempTrackingSpecification."Quantity (Base)" := -TempTrackingSpecification."Quantity (Base)";

                            ShowTotal := false;
                            if ItemTrackingAppendix.IsStartNewGroup(TempTrackingSpecification) then
                                ShowTotal := true;

                            ShowGroup := false;
                            if (TempTrackingSpecification."Source Ref. No." <> OldRefNo) or
                               (TempTrackingSpecification."Item No." <> OldNo)
                            then begin
                                OldRefNo := TempTrackingSpecification."Source Ref. No.";
                                OldNo := TempTrackingSpecification."Item No.";
                                TotalQty := 0;
                            end else
                                ShowGroup := true;
                            TotalQty += TempTrackingSpecification."Quantity (Base)";
                        end;

                        trigger OnPreDataItem()
                        begin
                            if TrackingSpecCount = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, TrackingSpecCount);
                            TempTrackingSpecification.SetCurrentKey(
                                "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
                                "Source Prod. Order Line", "Source Ref. No.");
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        // Item Tracking:
                        if ShowLotSN then begin
                            TrackingSpecCount := 0;
                            OldRefNo := 0;
                            ShowGroup := false;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                    TotalQty := 0;           // Item Tracking
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Service Shpt.-Printed", "Service Shipment Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := 1 + Abs(NoOfCopies);
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Service Shipment Header");
                FormatDocumentFields("Service Shipment Header");

                if not CompanyBankAccount.Get("Service Shipment Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service - Shipment';
        AboutText = 'Generate a service shipment document that you can send to your customer.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Service;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field("Show Correction Lines"; ShowCorrectionLines)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Correction Lines';
                        ToolTip = 'Specifies if the correction lines of an undoing of quantity posting will be shown on the report.';
                    }
                    field(ShowLotSN; ShowLotSN)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Lot/Serial No. Appendix';
                        ToolTip = 'Specifies if you want to print an appendix to the service shipment report that shows the lot and serial numbers that are in the shipment.';
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

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        ServiceSetup.Get();
        FormatDocument.SetLogoPosition(ServiceSetup."Logo Position on Documents", CompanyInfo1, CompanyInfo2, CompanyInfo3);
    end;

    var
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyBankAccount: Record "Bank Account";
        ServiceSetup: Record "Service Mgt. Setup";
        DimSetEntry: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingAppendix: Report "Item Tracking Appendix";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        TrackingSpecCount: Integer;
        OldRefNo: Integer;
        TotalQty: Decimal;
        OldNo: Code[20];
        CopyText: Text[30];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[20];
        ReferenceText: Text[80];
        DimText: Text[120];
        ShowCustAddr: Boolean;
        MoreLines: Boolean;
        ShowInternalInfo: Boolean;
        ShowCorrectionLines: Boolean;
        ShowLotSN: Boolean;
        ShowTotal: Boolean;
        ShowGroup: Boolean;
        OutputNo: Integer;
        DimTxtArrLength: Integer;
        DimTxtArr: array[500] of Text[50];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Service - Shipment %1';
        Text003: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemTrackingAppendixCaptionLbl: Label 'Item Tracking - Appendix';
        PhoneNoCaptionLbl: Label 'Phone No.';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccNoCaptionLbl: Label 'Account No.';
        ServiceShpHdrNoCaptionLbl: Label 'Shipment No.';
        ServiceShpHdrPostingDateCaptionLbl: Label 'Posting Date';
        HdrDimsCaptionLbl: Label 'Header Dimensions';
        SrvcShpItemLineCaptionLbl: Label 'Service Shipment Item Line';
        ServiceShpLineCaptionLbl: Label 'Service Shipment Line';
        QtyInvoicedCaptionLbl: Label 'Quantity Invoiced';
        QtyConsumedCaptionLbl: Label 'Quantity Consumed';
        LineDimsCaptionLbl: Label 'Line Dimensions';
        BilltoAddrCaptionLbl: Label 'Bill-to Address';
        QuantityCaptionLbl: Label 'Quantity';
        SerialNoCaptionLbl: Label 'Serial No.';
        LotNoCaptionLbl: Label 'Lot No.';
        DescriptionCaptionLbl: Label 'Description';
        DocumentDateLbl: Label 'Document Date';
        EmailIdCaptionLbl: Label 'Email';
        HomePageCaptionLbl: Label 'HomePage';
        SrvcShipHeaderCustNoCaptionLbl: Label 'Customer No';
        WarrantyCaptionLbl: Label 'Warranty';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";

    local procedure FindDimTxt(DimSetID: Integer)
    var
        Separation: Text[5];
        i: Integer;
        TxtToAdd: Text[120];
        StartNewLine: Boolean;
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimTxtArrLength := 0;
        for i := 1 to ArrayLen(DimTxtArr) do
            DimTxtArr[i] := '';
        if not DimSetEntry.FindSet() then
            exit;
        Separation := '; ';
        repeat
            TxtToAdd := DimSetEntry."Dimension Code" + ' - ' + DimSetEntry."Dimension Value Code";
            if DimTxtArrLength = 0 then
                StartNewLine := true
            else
                StartNewLine := StrLen(DimTxtArr[DimTxtArrLength]) + StrLen(Separation) + StrLen(TxtToAdd) > MaxStrLen(DimTxtArr[1]);
            if StartNewLine then begin
                DimTxtArrLength += 1;
                DimTxtArr[DimTxtArrLength] := TxtToAdd
            end else
                DimTxtArr[DimTxtArrLength] := DimTxtArr[DimTxtArrLength] + Separation + TxtToAdd;
        until DimSetEntry.Next() = 0;
    end;

    procedure InitializeRequest(NewShowInternalInfo: Boolean; NewShowCorrectionLines: Boolean; NewShowLotSN: Boolean)
    begin
        ShowInternalInfo := NewShowInternalInfo;
        ShowCorrectionLines := NewShowCorrectionLines;
        ShowLotSN := NewShowLotSN;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var ServiceShipmentHeader: Record "Service Shipment Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        FormatAddr.GetCompanyAddr(ServiceShipmentHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        ServiceFormatAddress.ServiceShptShipTo(ShipToAddr, ServiceShipmentHeader);
        ShowCustAddr := ServiceFormatAddress.ServiceShptBillTo(CustAddr, ShipToAddr, ServiceShipmentHeader);
    end;

    local procedure FormatDocumentFields(ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        FormatDocument.SetSalesPerson(SalesPurchPerson, ServiceShipmentHeader."Salesperson Code", SalesPersonText);

        ReferenceText := FormatDocument.SetText(ServiceShipmentHeader."Your Reference" <> '', ServiceShipmentHeader.FieldCaption("Your Reference"));
    end;
}

