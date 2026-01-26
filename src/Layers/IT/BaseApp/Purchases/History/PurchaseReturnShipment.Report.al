// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 6636 "Purchase - Return Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/History/PurchaseReturnShipment.rdlc';
    Caption = 'Purchase - Return Shipment';
    PreviewMode = PrintLayout;
    WordMergeDataItem = "Return Shipment Header";

    dataset
    {
        dataitem("Return Shipment Header"; "Return Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Posted Return Shipment';
            column(No_ReturnShptHeader; "No.")
            {
            }
            column(BuyFromContactPhoneNoLbl; BuyFromContactPhoneNoLbl)
            {
            }
            column(BuyFromContactMobilePhoneNoLbl; BuyFromContactMobilePhoneNoLbl)
            {
            }
            column(BuyFromContactEmailLbl; BuyFromContactEmailLbl)
            {
            }
            column(PayToContactPhoneNoLbl; PayToContactPhoneNoLbl)
            {
            }
            column(PayToContactMobilePhoneNoLbl; PayToContactMobilePhoneNoLbl)
            {
            }
            column(PayToContactEmailLbl; PayToContactEmailLbl)
            {
            }
            column(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
            {
            }
            column(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
            {
            }
            column(BuyFromContactEmail; BuyFromContact."E-Mail")
            {
            }
            column(PayToContactPhoneNo; PayToContact."Phone No.")
            {
            }
            column(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
            {
            }
            column(PayToContactEmail; PayToContact."E-Mail")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(CompanyInfoEmail; CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyPicture; DummyCompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoBankName; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfoBankAccountNo; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(DocDate_ReturnShptHeader; Format("Return Shipment Header"."Document Date", 0, 4))
                    {
                    }
                    column(PurchaserText; PurchaserText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourRef_ReturnShptHeader; "Return Shipment Header"."Your Reference")
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
                    column(BuyfromVendNo_ReturnShptHeader; "Return Shipment Header"."Buy-from Vendor No.")
                    {
                    }
                    column(BuyfromVendNo_ReturnShptHeaderCaption; "Return Shipment Header".FieldCaption("Buy-from Vendor No."))
                    {
                    }
                    column(ShptBuyFromAddr1; ShptBuyFromAddr[1])
                    {
                    }
                    column(ShptBuyFromAddr2; ShptBuyFromAddr[2])
                    {
                    }
                    column(ShptBuyFromAddr3; ShptBuyFromAddr[3])
                    {
                    }
                    column(ShptBuyFromAddr4; ShptBuyFromAddr[4])
                    {
                    }
                    column(ShptBuyFromAddr5; ShptBuyFromAddr[5])
                    {
                    }
                    column(ShptBuyFromAddr6; ShptBuyFromAddr[6])
                    {
                    }
                    column(ShptBuyFromAddr7; ShptBuyFromAddr[7])
                    {
                    }
                    column(ShptBuyFromAddr8; ShptBuyFromAddr[8])
                    {
                    }
                    column(PageCaption; StrSubstNo(Text003, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PurchaseReturnShptCaption; StrSubstNo(Text002, CopyText) + TDDHeaderTxt)
                    {
                    }
                    column(ContracterTxt; ContracterTxt)
                    {
                    }
                    column(AddInfo_ReturnShptHeader; "Return Shipment Header"."Additional Information")
                    {
                    }
                    column(AddlNotes_ReturnShptHeader; "Return Shipment Header"."Additional Notes")
                    {
                    }
                    column(AddlInstruc_ReturnShptHeader; "Return Shipment Header"."Additional Instructions")
                    {
                    }
                    column(TDDPrepdBy_ReturnShptHeader; "Return Shipment Header"."TDD Prepared By")
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
                    column(BankAccountNoCaption; BankAccountNoCaptionLbl)
                    {
                    }
                    column(ShipmentNoCaption; ShipmentNoCaptionLbl)
                    {
                    }
                    column(AddlDeclarationInfoCaption; AddlDeclarationInfoCaptionLbl)
                    {
                    }
                    column(NotesCaption; NotesCaptionLbl)
                    {
                    }
                    column(AddlInstructionsCaption; AddlInstructionsCaptionLbl)
                    {
                    }
                    column(CompiledByCaption; CompiledByCaptionLbl)
                    {
                    }
                    column(ShippingAgentCaption; ShippingAgentCaptionLbl)
                    {
                    }
                    column(LoaderCaption; LoaderCaptionLbl)
                    {
                    }
                    column(HomePageCaption; HomePageCaptionLbl)
                    {
                    }
                    column(EmailCaption; EmailCaptionLbl)
                    {
                    }
                    column(DocumentDateCaption; DocumentDateCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Return Shipment Header";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText_DimensionLoop1; DimText)
                        {
                        }
                        column(DimensionLoop1No; DimensionLoop1.Number)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 - %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Return Shipment Line"; "Return Shipment Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Return Shipment Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(TypeInt; TypeInt)
                        {
                        }
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(Desc_ReturnShptLine; Description)
                        {
                        }
                        column(UOM_ReturnShptLine; "Unit of Measure")
                        {
                        }
                        column(Quantity_ReturnShptLine; Quantity)
                        {
                        }
                        column(No_ReturnShptLine; "No.")
                        {
                        }
                        column(LineNo_ReturnShptLine; "Line No.")
                        {
                        }
                        column(Desc_ReturnShptLineCaption; FieldCaption(Description))
                        {
                        }
                        column(UOM_ReturnShptLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Quantity_ReturnShptLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(No_ReturnShptLineCaption; FieldCaption("No."))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_DimensionLoop2; DimText)
                            {
                            }
                            column(DimensionLoop2No; DimensionLoop2.Number)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 - %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if (not ShowCorrectionLines) and Correction then
                                CurrReport.Skip();

                            DimSetEntry2.SetRange("Dimension Set ID", "Dimension Set ID");
                            TypeInt := Type.AsInteger();

                            if FirstLineHasBeenOutput then
                                Clear(DummyCompanyInfo.Picture);
                            FirstLineHasBeenOutput := true;
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                            FirstLineHasBeenOutput := false;
                            DummyCompanyInfo.Picture := CompanyInfo.Picture;
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));

                        trigger OnAfterGetRecord()
                        begin
                            PayToVendorNo := "Return Shipment Header"."Pay-to Vendor No.";
                            BuyFromVendorNo := "Return Shipment Header"."Buy-from Vendor No.";
                            PayToCaption := "Return Shipment Header".FieldCaption("Pay-to Vendor No.");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if "Return Shipment Header"."Buy-from Vendor No." = "Return Shipment Header"."Pay-to Vendor No." then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ShptShipToAddr1; ShptShipToAddr[1])
                        {
                        }
                        column(ShptShipToAddr2; ShptShipToAddr[2])
                        {
                        }
                        column(ShptShipToAddr3; ShptShipToAddr[3])
                        {
                        }
                        column(ShptShipToAddr4; ShptShipToAddr[4])
                        {
                        }
                        column(ShptShipToAddr5; ShptShipToAddr[5])
                        {
                        }
                        column(ShptShipToAddr6; ShptShipToAddr[6])
                        {
                        }
                        column(ShptShipToAddr7; ShptShipToAddr[7])
                        {
                        }
                        column(ShptShipToAddr8; ShptShipToAddr[8])
                        {
                        }
                        column(PayToVendorNo; PayToVendorNo)
                        {
                        }
                        column(BuyFromVendorNo; BuyFromVendorNo)
                        {
                        }
                        column(PayToCaption; PayToCaption)
                        {
                        }
                        column(ShptShipToAddrCaption; ShptShipToAddrCaptionLbl)
                        {
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    FirstLineHasBeenOutput := false;
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Return Shipment - Printed", "Return Shipment Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                Language: Codeunit Language;
            begin
                FirstLineHasBeenOutput := false;
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := Language.GetFormatRegionOrDefault("Format Region");
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

                FormatAddressFields("Return Shipment Header");
                FormatDocumentFields("Return Shipment Header");
                if BuyFromContact.Get("Buy-from Contact No.") then;
                if PayToContact.Get("Pay-to Contact No.") then;

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");
            end;

            trigger OnPreDataItem()
            begin
                FirstLineHasBeenOutput := false;
            end;

            trigger OnPostDataItem()
            begin
                OnAfterPostDataItem("Return Shipment Header");
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(ShowCorrectionLines; ShowCorrectionLines)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Show Correction Lines';
                        ToolTip = 'Specifies if the correction lines of an undoing of quantity posting will be shown on the report.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to log this interaction.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            InitLogInteraction();
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.SetAutoCalcFields(Picture);
        CompanyInfo.Get();

        OnAfterInitReport();
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Return Shipment Header".FindSet() then
                repeat
                    SegManagement.LogDocument(21, "Return Shipment Header"."No.", 0, 0, DATABASE::Vendor,
                      "Return Shipment Header"."Buy-from Vendor No.", "Return Shipment Header"."Purchaser Code", '',
                      "Return Shipment Header"."Posting Description", '');
                until "Return Shipment Header".Next() = 0;
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'Purchase - Return Shipment %1', Comment = '%1 = Document No.';
#pragma warning disable AA0470
        Text003: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DummyCompanyInfo: Record "Company Information";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        ShptBuyFromAddr: array[8] of Text[100];
        PurchaserText: Text[50];
        ReferenceText: Text[80];
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[75];
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        MoreLines: Boolean;
        ShowCorrectionLines: Boolean;
        LogInteraction: Boolean;
        OutputNo: Integer;
        TypeInt: Integer;
        PayToVendorNo: Code[20];
        BuyFromVendorNo: Code[20];
        PayToCaption: Text[30];
        LogInteractionEnable: Boolean;
        TDDHeaderTxt: Text[70];
        ContracterTxt: Text[30];
        ShippingAgentAddr: array[8] of Text[100];
        LoaderAddr: array[8] of Text[100];
        Text12100: Label 'Contractor/Goods owner';
        Text12101: Label 'Transport Delivery Document';
        TDDDocument: Boolean;
        PhoneNoCaptionLbl: Label 'Phone No.';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccountNoCaptionLbl: Label 'Account No.';
        ShipmentNoCaptionLbl: Label 'Shipment No.';
        AddlDeclarationInfoCaptionLbl: Label 'Additional Declaration Information:';
        NotesCaptionLbl: Label 'Notes:';
        AddlInstructionsCaptionLbl: Label 'Additional Instructions:';
        CompiledByCaptionLbl: Label 'Compiled by:';
        ShippingAgentCaptionLbl: Label 'Shipping Agent:';
        LoaderCaptionLbl: Label 'Loader:';
        HomePageCaptionLbl: Label 'Home Page';
        EmailCaptionLbl: Label 'Email';
        DocumentDateCaptionLbl: Label 'Document Date';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        ShptShipToAddrCaptionLbl: Label 'Ship-to Address';
        BuyFromContactPhoneNoLbl: Label 'Buy-from Contact Phone No.';
        BuyFromContactMobilePhoneNoLbl: Label 'Buy-from Contact Mobile Phone No.';
        BuyFromContactEmailLbl: Label 'Buy-from Contact E-Mail';
        PayToContactPhoneNoLbl: Label 'Pay-to Contact Phone No.';
        PayToContactMobilePhoneNoLbl: Label 'Pay-to Contact Mobile Phone No.';
        PayToContactEmailLbl: Label 'Pay-to Contact E-Mail';

    protected var
        CompanyInfo: Record "Company Information";
        FirstLineHasBeenOutput: Boolean;
        ShptShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];

    procedure InitializeRequest(NewNoOfCopies: Decimal; NewShowInternalInfo: Boolean; NewShowCorrectionLines: Boolean; NewLogInteraction: Boolean)
    begin
        NoOfCopies := NewNoOfCopies;
        ShowInternalInfo := NewShowInternalInfo;
        ShowCorrectionLines := NewShowCorrectionLines;
        LogInteraction := NewLogInteraction;
    end;

    local procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Purch. Return Shipment") <> '';
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        if RespCenter.Get(ReturnShipmentHeader."Responsibility Center") then begin
            FormatAddr.RespCenter(CompanyAddr, RespCenter);
            CompanyInfo."Phone No." := RespCenter."Phone No.";
            CompanyInfo."Fax No." := RespCenter."Fax No.";
        end else begin
            FormatAddr.Company(CompanyAddr, CompanyInfo);
            if TDDDocument then
                CompanyInfo.GetTDDAddr(CompanyAddr);
        end;
        FormatAddr.PurchShptBuyFrom(ShptBuyFromAddr, ReturnShipmentHeader);
        FormatAddr.PurchShptShipTo(ShptShipToAddr, ReturnShipmentHeader);
    end;

    local procedure FormatDocumentFields(ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        FormatDocument.SetPurchaser(SalesPurchPerson, ReturnShipmentHeader."Purchaser Code", PurchaserText);

        ReferenceText := FormatDocument.SetText(ReturnShipmentHeader."Your Reference" <> '', ReturnShipmentHeader.FieldCaption("Your Reference"));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostDataItem(var ReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;
}

