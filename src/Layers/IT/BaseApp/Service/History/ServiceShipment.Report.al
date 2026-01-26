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
                    column(CompanyInfoPicture; CompanyInfo.Picture)
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
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(ShipToAddr6; ShipToAddr[6])
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
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
                    column(CustNo_ServShptHeader; "Service Shipment Header"."Customer No.")
                    {
                    }
                    column(CustNo_ServShptHeaderCaption; "Service Shipment Header".FieldCaption("Customer No."))
                    {
                    }
                    column(DocDate_ServShptHeader; Format("Service Shipment Header"."Document Date", 0, 4))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourRef_ServShptHeader; "Service Shipment Header"."Your Reference")
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
                    column(PostingDate_ServShptHeader; Format("Service Shipment Header"."Posting Date"))
                    {
                    }
                    column(PageCaption; StrSubstNo(Text003, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(ServShptCopy; StrSubstNo(Text002, CopyText) + TDDHeaderTxt)
                    {
                    }
                    column(ContracterTxt; ContracterTxt)
                    {
                    }
                    column(AddInfo_ServShptHeader; "Service Shipment Header"."Additional Information")
                    {
                    }
                    column(AddNotes_ServShptHeader; "Service Shipment Header"."Additional Notes")
                    {
                    }
                    column(AddInst_ServShptHeader; "Service Shipment Header"."Additional Instructions")
                    {
                    }
                    column(TDDPrepBy_ServShptHeader; "Service Shipment Header"."TDD Prepared By")
                    {
                    }
                    column(ShippingAgentAddr1; ShippingAgentAddr[1])
                    {
                    }
                    column(ShippingAgentAddr2; ShippingAgentAddr[2])
                    {
                    }
                    column(LoaderAddr1; LoaderAddr[1])
                    {
                    }
                    column(LoaderAddr2; LoaderAddr[2])
                    {
                    }
                    column(ShippingAgentAddr3; ShippingAgentAddr[3])
                    {
                    }
                    column(LoaderAddr3; LoaderAddr[3])
                    {
                    }
                    column(ShippingAgentAddr4; ShippingAgentAddr[4])
                    {
                    }
                    column(LoaderAddr4; LoaderAddr[4])
                    {
                    }
                    column(ShippingAgentAddr5; ShippingAgentAddr[5])
                    {
                    }
                    column(LoaderAddr5; LoaderAddr[5])
                    {
                    }
                    column(ItemTrackingAppendixCaption; ItemTrackingAppendixCaptionLbl)
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankAccountNoCaption; CompanyInfoBankAccountNoCaptionLbl)
                    {
                    }
                    column(ServiceShipmentHeaderNoCaption; ServiceShipmentHeaderNoCaptionLbl)
                    {
                    }
                    column(ServiceShipmentHeaderPostingDateCaption; ServiceShipmentHeaderPostingDateCaptionLbl)
                    {
                    }
                    column(ServiceShipmentHeaderAdditionalInformationCaption; ServiceShipmentHeaderAdditionalInformationCaptionLbl)
                    {
                    }
                    column(ServiceShipmentHeaderAdditionalNotesCaption; ServiceShipmentHeaderAdditionalNotesCaptionLbl)
                    {
                    }
                    column(ServiceShipmentHeaderAdditionalInstructionsCaption; ServiceShipmentHeaderAdditionalInstructionsCaptionLbl)
                    {
                    }
                    column(ServiceShipmentHeaderTDDPreparedByCaption; ServiceShipmentHeaderTDDPreparedByCaptionLbl)
                    {
                    }
                    column(ShippingAgentAddr1Caption; ShippingAgentAddr1CaptionLbl)
                    {
                    }
                    column(LoaderAddr1Caption; LoaderAddr1CaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Service Shipment Header";
                        DataItemTableView = sorting(Number);
                        column(DimText; DimText)
                        {
                        }
                        column(Number_IntegerLine; DimensionLoop1.Number)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
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
                        column(ContractNo_ServShptItemLine; "Contract No.")
                        {
                        }
                        column(Warranty_ServShptItemLine; Warranty)
                        {
                        }
                        column(Desc_ServShptItemLine; Description)
                        {
                        }
                        column(SerialNo_ServShptItemLine; "Serial No.")
                        {
                        }
                        column(ItemNo_ServShptItemLine; "Item No.")
                        {
                        }
                        column(ServItemGrCode_ServShptItemLine; "Service Item Group Code")
                        {
                        }
                        column(ServItemNo_ServShptItemLine; "Service Item No.")
                        {
                        }
                        column(ServItemNo_ServShptItemLineCaption; FieldCaption("Service Item No."))
                        {
                        }
                        column(ServItemGrCode_ServShptItemLineCaption; FieldCaption("Service Item Group Code"))
                        {
                        }
                        column(ItemNo_ServShptItemLineCaption; FieldCaption("Item No."))
                        {
                        }
                        column(SerialNo_ServShptItemLineCaption; FieldCaption("Serial No."))
                        {
                        }
                        column(Desc_ServShptItemLineCaption; FieldCaption(Description))
                        {
                        }
                        column(Warranty_ServShptItemLineCaption; FieldCaption(Warranty))
                        {
                        }
                        column(ContractNo_ServShptItemLineCaption; FieldCaption("Contract No."))
                        {
                        }
                        column(Warranty; Format(Warranty))
                        {
                        }
                        column(LineNo_ServShptItemLine; "Line No.")
                        {
                        }
                        column(ServiceShipmentItemLineCaption; ServiceShipmentItemLineCaptionLbl)
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
                        column(Type_ServShptLine; Type)
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
                        column(UOM_ServShptLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Quantity_ServShptLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(Description_ServShptLineCaption; FieldCaption(Description))
                        {
                        }
                        column(No_ServShptLineCaption; FieldCaption("No."))
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
                        column(ServiceShipmentLineCaption; ServiceShipmentLineCaptionLbl)
                        {
                        }
                        column(QuantityInvoicedCaption; QuantityInvoicedCaptionLbl)
                        {
                        }
                        column(QuantityConsumedCaption; QuantityConsumedCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimText_DimensionLoop2; DimText)
                            {
                            }
                            column(Number_DimensionLoop2; DimensionLoop2.Number)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
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
                        column(BilltoCustNo_ServShptHeader; "Service Shipment Header"."Bill-to Customer No.")
                        {
                        }
                        column(BilltoCustNo_ServShptHeaderCaption; "Service Shipment Header".FieldCaption("Bill-to Customer No."))
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
                        column(BilltoAddressCaption; BilltoAddressCaptionLbl)
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
                        column(TrackingSpecBufferItemNo; TempTrackingSpecification."Item No.")
                        {
                        }
                        column(TrackingSpecBufferDesc; TempTrackingSpecification.Description)
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
                            column(TotalQuantity; TotalQty)
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

                TDDDocument := CheckTDDData();
                if TDDDocument then begin
                    ContracterTxt := Text12100;
                    TDDHeaderTxt := ' / ' + Text12101;
                    GetTDDAddr(ShippingAgentAddr, LoaderAddr);
                end else begin
                    ContracterTxt := '';
                    TDDHeaderTxt := '';
                end;

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

        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                CompanyInfo.CalcFields(Picture);
            ServiceSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
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
        Text12100: Label 'Contractor/Goods owner';
        Text12101: Label 'Transport Delivery Document';
        TDDHeaderTxt: Text[60];
        ContracterTxt: Text[30];
        ShippingAgentAddr: array[8] of Text[100];
        LoaderAddr: array[8] of Text[100];
        TDDDocument: Boolean;
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
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccountNoCaptionLbl: Label 'Account No.';
        ServiceShipmentHeaderNoCaptionLbl: Label 'Shipment No.';
        ServiceShipmentHeaderPostingDateCaptionLbl: Label 'Posting Date';
        ServiceShipmentHeaderAdditionalInformationCaptionLbl: Label 'Additional Declaration Information:';
        ServiceShipmentHeaderAdditionalNotesCaptionLbl: Label 'Notes:';
        ServiceShipmentHeaderAdditionalInstructionsCaptionLbl: Label 'Additional Instructions:';
        ServiceShipmentHeaderTDDPreparedByCaptionLbl: Label 'Compiled by:';
        ShippingAgentAddr1CaptionLbl: Label 'Shipping Agent:';
        LoaderAddr1CaptionLbl: Label 'Loader:';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        ServiceShipmentItemLineCaptionLbl: Label 'Service Shipment Item Line';
        ServiceShipmentLineCaptionLbl: Label 'Service Shipment Line';
        QuantityInvoicedCaptionLbl: Label 'Quantity Invoiced';
        QuantityConsumedCaptionLbl: Label 'Quantity Consumed';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        BilltoAddressCaptionLbl: Label 'Bill-to Address';
        QuantityCaptionLbl: Label 'Quantity';
        SerialNoCaptionLbl: Label 'Serial No.';
        LotNoCaptionLbl: Label 'Lot No.';
        DescriptionCaptionLbl: Label 'Description';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";

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
        if RespCenter.Get(ServiceShipmentHeader."Responsibility Center") then begin
            FormatAddr.RespCenter(CompanyAddr, RespCenter);
            CompanyInfo."Phone No." := RespCenter."Phone No.";
            CompanyInfo."Fax No." := RespCenter."Fax No.";
        end else begin
            FormatAddr.Company(CompanyAddr, CompanyInfo);
            if TDDDocument then
                CompanyInfo.GetTDDAddr(CompanyAddr);
        end;
        ServiceFormatAddress.ServiceShptShipTo(ShipToAddr, ServiceShipmentHeader);
        ShowCustAddr := ServiceFormatAddress.ServiceShptBillTo(CustAddr, ShipToAddr, ServiceShipmentHeader);
    end;

    local procedure FormatDocumentFields(ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        FormatDocument.SetSalesPerson(SalesPurchPerson, ServiceShipmentHeader."Salesperson Code", SalesPersonText);

        ReferenceText := FormatDocument.SetText(ServiceShipmentHeader."Your Reference" <> '', ServiceShipmentHeader.FieldCaption("Your Reference"));
    end;
}

