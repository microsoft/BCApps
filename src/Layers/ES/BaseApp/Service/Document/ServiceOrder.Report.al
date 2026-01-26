// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 5900 "Service Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Document/ServiceOrder.rdlc';
    Caption = 'Service Order';
    WordMergeDataItem = "Service Header";

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Customer No.";
            column(No_ServHeader; "No.")
            {
            }
            column(No_ServHeaderCaption; FieldCaption("No."))
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfoPicture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(ContractNo_ServHeader; "Service Header"."Contract No.")
                    {
                    }
                    column(OrderTime_ServHeader; "Service Header"."Order Time")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(OrderDate_ServHeader; Format("Service Header"."Order Date"))
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(Status_ServHeader; "Service Header".Status)
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CompanyAddr8; CompanyAddr[8])
                    {
                    }
                    column(CompanyAddr7; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(BilltoName_ServHeader; "Service Header"."Bill-to Name")
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(ServOrderCopyText; StrSubstNo(Text001, CopyText))
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(PhoneNo_ServHeader; "Service Header"."Phone No.")
                    {
                    }
                    column(Email_ServHeader; "Service Header"."E-Mail")
                    {
                    }
                    column(Description_ServHeader; "Service Header".Description)
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ' '))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(ContractNoCaption; ContractNoCaptionLbl)
                    {
                    }
                    column(ServiceHeaderOrderDateCaption; ServiceHeaderOrderDateCaptionLbl)
                    {
                    }
                    column(InvoicetoCaption; InvoicetoCaptionLbl)
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
                    {
                    }
                    column(ServiceHeaderEMailCaption; ServiceHeaderEMailCaptionLbl)
                    {
                    }
                    column(OrderTime_ServHeaderCaption; "Service Header".FieldCaption("Order Time"))
                    {
                    }
                    column(Status_ServHeaderCaption; "Service Header".FieldCaption(Status))
                    {
                    }
                    column(Description_ServHeaderCaption; "Service Header".FieldCaption(Description))
                    {
                    }
                    column(CACCaption; CACCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_DimensionLoop1; Number)
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
                                    DimText := StrSubstNo('%1 %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1, %2 %3', DimText,
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
                    dataitem("Service Order Comment"; "Service Comment Line")
                    {
                        DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(General));
                        column(Comment_ServOrderComment; Comment)
                        {
                        }
                        column(TabName_ServOrderComment; "Table Name")
                        {
                        }
                        column(No_ServOrderComment; "No.")
                        {
                        }
                        column(TableLineNo_ServOrderComment; "Table Line No.")
                        {
                        }
                    }
                    dataitem("Service Item Line"; "Service Item Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(LineNo_ServItemLine; "Line No.")
                        {
                        }
                        column(SerialNo_ServItemLine; "Serial No.")
                        {
                        }
                        column(Description_ServItemLine; Description)
                        {
                        }
                        column(ItemNo_ServItemLineServ; "Service Item No.")
                        {
                        }
                        column(ServItemGroupCode_ServItemLine; "Service Item Group Code")
                        {
                        }
                        column(Warranty_ServItemLine; Format(Warranty))
                        {
                        }
                        column(LoanerNo_ServItemLine; "Loaner No.")
                        {
                        }
                        column(RepairStatusCode_ServItemLine; "Repair Status Code")
                        {
                        }
                        column(ServShelfNo_ServItemLine; "Service Shelf No.")
                        {
                        }
                        column(ResponseTime_ServItemLine; Format("Response Time"))
                        {
                        }
                        column(ResponseDate_ServItemLine; Format("Response Date"))
                        {
                        }
                        column(DocumentNo_ServItemLine; "Document No.")
                        {
                        }
                        column(ServiceItemLineWarrantyCaption; CaptionClassTranslate(FieldCaption(Warranty)))
                        {
                        }
                        column(ServiceItemLinesCaption; ServiceItemLinesCaptionLbl)
                        {
                        }
                        column(ServiceItemLineResponseDateCaption; ServiceItemLineResponseDateCaptionLbl)
                        {
                        }
                        column(ServiceItemLineResponseTimeCaption; ServiceItemLineResponseTimeCaptionLbl)
                        {
                        }
                        column(SerialNo_ServItemLineCaption; FieldCaption("Serial No."))
                        {
                        }
                        column(Description_ServItemLineCaption; FieldCaption(Description))
                        {
                        }
                        column(ItemNo_ServItemLineServCaption; FieldCaption("Service Item No."))
                        {
                        }
                        column(ServItemGroupCode_ServItemLineCaption; FieldCaption("Service Item Group Code"))
                        {
                        }
                        column(LoanerNo_ServItemLineCaption; FieldCaption("Loaner No."))
                        {
                        }
                        column(RepairStatusCode_ServItemLineCaption; FieldCaption("Repair Status Code"))
                        {
                        }
                        column(ServShelfNo_ServItemLineCaption; FieldCaption("Service Shelf No."))
                        {
                        }
                        dataitem("Fault Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Fault));
                            column(Comment_FaultComment; Comment)
                            {
                            }
                            column(TableSubtype_FaultComment; "Table Subtype")
                            {
                            }
                            column(Type_FaultComment; Type)
                            {
                            }
                            column(LineNo_FaultComment; "Line No.")
                            {
                            }
                            column(FaultCommentsCaption; FaultCommentsCaptionLbl)
                            {
                            }
                        }
                        dataitem("Resolution Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Resolution));
                            column(Comment_ResolutionComment; Comment)
                            {
                            }
                            column(TableSubtype_ResolutionComment; "Table Subtype")
                            {
                            }
                            column(Type_ResolutionComment; Type)
                            {
                            }
                            column(LineNo_ResolutionComment; "Line No.")
                            {
                            }
                            column(ResolutionCommentsCaption; ResolutionCommentsCaptionLbl)
                            {
                            }
                        }
                    }
                    dataitem("Service Line"; "Service Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(ServLineLineNo; "Line No.")
                        {
                        }
                        column(TotalAmt; TotalAmt)
                        {
                        }
                        column(TotalGrossAmt; TotalGrossAmt)
                        {
                        }
                        column(ServItemSerialNo_ServLine; "Service Item Serial No.")
                        {
                        }
                        column(Type_ServLine; Type)
                        {
                        }
                        column(No_ServLine; "No.")
                        {
                        }
                        column(VariantCode_ServLine; "Variant Code")
                        {
                        }
                        column(Description_ServLine; Description)
                        {
                        }
                        column(Qty; Qty)
                        {
                        }
                        column(UnitPrice_ServLine; "Unit Price")
                        {
                        }
                        column(LineDiscount_ServLine; "Line Discount %")
                        {
                        }
                        column(Amt; Amt)
                        {
                        }
                        column(GrossAmt; GrossAmt)
                        {
                        }
                        column(QtyConsumed_ServLine; "Quantity Consumed")
                        {
                        }
                        column(QtytoConsume_ServLine; "Qty. to Consume")
                        {
                        }
                        column(DocumentNo_ServLine; "Document No.")
                        {
                        }
                        column(QtyCaption; QtyCaptionLbl)
                        {
                        }
                        column(ServiceLinesCaption; ServiceLinesCaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(GrossAmountCaption; GrossAmountCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }
                        column(ServItemSerialNo_ServLineCaption; FieldCaption("Service Item Serial No."))
                        {
                        }
                        column(Type_ServLineCaption; FieldCaption(Type))
                        {
                        }
                        column(No_ServLineCaption; FieldCaption("No."))
                        {
                        }
                        column(VariantCode_ServLineCaption; FieldCaption("Variant Code"))
                        {
                        }
                        column(Description_ServLineCaption; FieldCaption(Description))
                        {
                        }
                        column(UnitPrice_ServLineCaption; FieldCaption("Unit Price"))
                        {
                        }
                        column(LineDiscount_ServLineCaption; FieldCaption("Line Discount %"))
                        {
                        }
                        column(QtyConsumed_ServLineCaption; FieldCaption("Quantity Consumed"))
                        {
                        }
                        column(QtytoConsume_ServLineCaption; FieldCaption("Qty. to Consume"))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText2; DimText)
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
                                        DimText := StrSubstNo('%1 %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1, %2 %3', DimText,
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

                                DimSetEntry2.SetRange("Dimension Set ID", "Service Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if ShowQty = ShowQty::Quantity then begin
                                Qty := Quantity;
                                Amt := "Line Amount";
                                GrossAmt := "Amount Including VAT";
                            end else begin
                                if "Quantity Invoiced" = 0 then
                                    CurrReport.Skip();
                                Qty := "Quantity Invoiced";

                                Amt := Round((Qty * "Unit Price") * (1 - "Line Discount %" / 100));
                                GrossAmt := (1 + "VAT %" / 100) * Amt;
                            end;

                            TotalAmt += Amt;
                            TotalGrossAmt += GrossAmt;
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(Amt);
                            Clear(GrossAmt);

                            TotalAmt := 0;
                            TotalGrossAmt := 0;
                        end;
                    }
                    dataitem(Shipto; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ShipToAddr6; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr5; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr4; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr3; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr2; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr1; ShipToAddr[1])
                        {
                        }
                        column(ShiptoAddressCaption; ShiptoAddressCaptionLbl)
                        {
                        }
                        column(ShipToPhoneNo; "Service Header"."Ship-to Phone")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);

                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Service Header");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                ShowCashAccountingCriteria("Service Header");

                if not IsReportInPreviewMode() and
                   ((CurrReport.UseRequestPage()) and ArchiveDocument or
                   not (CurrReport.UseRequestPage()) and (ServiceSetup."Archive Orders"))
                then begin
                    CurrReport.Language(LanguageMgt.GetLanguageIdOrDefault(LanguageMgt.GetUserLanguageCode()));
                    ServiceDocumentArchiveMgmt.ArchServiceDocumentNoConfirm("Service Header");
                    CurrReport.Language(LanguageMgt.GetLanguageIdOrDefault("Language Code"));
                end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Order';
        AboutText = 'Generate a service order document that you can send to your customer.';

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
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = Service;
                        Caption = 'Archive Document';
                        ToolTip = 'Specifies if the document is archived after you preview or print it.';
                    }
                    field(ShowQty; ShowQty)
                    {
                        ApplicationArea = Service;
                        Caption = 'Amounts Based on';
                        OptionCaption = 'Quantity,Quantity Invoiced';
                        ToolTip = 'Specifies the amounts that the service order is based on.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ArchiveDocument := ServiceSetup."Archive Orders";
        end;
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
        CompanyInfo3: Record "Company Information";
        ServiceSetup: Record "Service Mgt. Setup";
        RespCenter: Record "Responsibility Center";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        ShowShippingAddr: Boolean;
        ArchiveDocument: Boolean;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[120];
        Qty: Decimal;
        Amt: Decimal;
        ShowQty: Option Quantity,"Quantity Invoiced";
        GrossAmt: Decimal;
        TotalAmt: Decimal;
        TotalGrossAmt: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Service Order %1';
        Text002: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ContractNoCaptionLbl: Label 'Contract No.';
        ServiceHeaderOrderDateCaptionLbl: Label 'Order Date';
        InvoicetoCaptionLbl: Label 'Invoice to';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        ServiceHeaderEMailCaptionLbl: Label 'Email';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        ServiceItemLinesCaptionLbl: Label 'Service Item Lines';
        ServiceItemLineResponseDateCaptionLbl: Label 'Response Date';
        ServiceItemLineResponseTimeCaptionLbl: Label 'Response Time';
        FaultCommentsCaptionLbl: Label 'Fault Comments';
        ResolutionCommentsCaptionLbl: Label 'Resolution Comments';
        QtyCaptionLbl: Label 'Quantity';
        ServiceLinesCaptionLbl: Label 'Service Lines';
        AmountCaptionLbl: Label 'Amount';
        GrossAmountCaptionLbl: Label 'Gross Amount';
        TotalCaptionLbl: Label 'Total';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        CACCaptionLbl: Text;
        CACTxt: Label 'R,gimen especial del criterio de caja';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview() or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure InitializeRequest(ShowInternalInfoFrom: Boolean; ShowQtyFrom: Option)
    begin
        ShowInternalInfo := ShowInternalInfoFrom;
        ShowQty := ShowQtyFrom;
    end;

    local procedure FormatAddressFields(var ServiceHeader: Record "Service Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        FormatAddr.GetCompanyAddr(ServiceHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        ServiceFormatAddress.ServiceOrderSellto(CustAddr, ServiceHeader);
        ShowShippingAddr := ServiceHeader."Ship-to Code" <> '';
        if ShowShippingAddr then
            ServiceFormatAddress.ServiceOrderShipto(ShipToAddr, ServiceHeader);
    end;

    [Scope('OnPrem')]
    procedure ShowCashAccountingCriteria(ServiceHeader: Record "Service Header"): Text
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceLine: Record "Service Line";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if not GLSetup."VAT Cash Regime" then
            exit;
        CACCaptionLbl := '';
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                if VATPostingSetup.Get(ServiceHeader."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
                    if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then
                        CACCaptionLbl := CACTxt;
            until (ServiceLine.Next() = 0) or (CACCaptionLbl <> '');
        exit(CACCaptionLbl);
    end;
}

